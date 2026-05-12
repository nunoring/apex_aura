import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show Rect;
import 'package:image/image.dart' as img;

class FaceDetectorService {
  static final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: false,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // 여러 장 분석 후 수치 평균 — 동물상 분류 안정성 향상
  static Future<Map<String, dynamic>?> analyzeMultiplePhotos(
    List<File> imageFiles, {
    int primaryFaceIndex = 0,
  }) async {
    if (imageFiles.isEmpty) return null;
    if (imageFiles.length == 1) return analyzeFace(imageFiles[0]);

    final results = <Map<String, dynamic>>[];
    for (int i = 0; i < imageFiles.length; i++) {
      // 대표 사진(첫 번째)은 선택된 faceIndex 사용, 나머지는 face[0]
      final faceIdx = i == 0 ? primaryFaceIndex : 0;
      final r = await analyzeFace(imageFiles[i], faceIndex: faceIdx);
      if (r != null) results.add(r);
    }
    if (results.isEmpty) return null;
    if (results.length == 1) return results[0];

    // 수치 필드 평균 계산 (분류용 지표만 — 오버레이 좌표는 대표사진 그대로 유지)
    final averaged = Map<String, dynamic>.from(results[0]);
    final numericKeys = [
      'eye_angle', 'face_ratio', 'eye_gap_ratio', 'golden_ratio',
    ];
    // 오버레이/이미지 좌표는 대표사진(results[0])에서 가져옴 — 평균 안 냄
    // (averaged가 이미 results[0] 복사본이므로 별도 처리 불필요)

    for (final key in numericKeys) {
      final vals = results
          .where((r) => r[key] != null)
          .map((r) {
            final v = r[key];
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? 0.0;
            return 0.0;
          })
          .toList();
      if (vals.isEmpty) continue;
      final avg = vals.reduce((a, b) => a + b) / vals.length;

      // 원래 타입 유지
      final orig = results[0][key];
      if (orig is String) {
        averaged[key] = avg.toStringAsFixed(orig.contains('.') ? orig.split('.')[1].length : 1);
      } else {
        averaged[key] = avg;
      }
    }

    // 평균 수치로 동물상 재분류 (yaw 포함)
    final eyeAngle = double.tryParse(averaged['eye_angle']?.toString() ?? '0') ?? 0.0;
    final faceRatio = double.tryParse(averaged['face_ratio']?.toString() ?? '0') ?? 0.0;
    final eyeGapRatio = double.tryParse(averaged['eye_gap_ratio']?.toString() ?? '0') ?? 0.0;
    final headYaw = double.tryParse(averaged['head_yaw']?.toString() ?? '0') ?? 0.0;
    final goldenRatio = double.tryParse(averaged['golden_ratio']?.toString() ?? '0.33') ?? 0.33;
    final noseWidthRatio = double.tryParse(averaged['nose_width_ratio']?.toString() ?? '1.0') ?? 1.0;
    averaged.addAll(_classifyFaceTypeDetailed(
      eyeAngle: eyeAngle,
      faceRatio: faceRatio,
      eyeGapRatio: eyeGapRatio,
      headYaw: headYaw,
      goldenRatio: goldenRatio,
      noseWidthRatio: noseWidthRatio,
    ));
    averaged['photo_count'] = results.length;

    return averaged;
  }

  // 빠른 얼굴 감지 (선택 화면용) — 바운딩박스와 이미지 크기만 반환
  static Future<({List<Rect> boxes, double imageW, double imageH})?> detectFaces(File imageFile) async {
    File? tempFile;
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final oriented = img.bakeOrientation(decoded);

      final tempDir = await Directory.systemTemp.createTemp('apex_');
      tempFile = File('${tempDir.path}/oriented.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(oriented, quality: 92));

      final faces = await _detector.processImage(InputImage.fromFile(tempFile));
      return (
        boxes: faces.map((f) => f.boundingBox).toList(),
        imageW: oriented.width.toDouble(),
        imageH: oriented.height.toDouble(),
      );
    } catch (e) {
      return null;
    } finally {
      await tempFile?.parent.delete(recursive: true);
    }
  }

  static Future<Map<String, dynamic>?> analyzeFace(File imageFile, {int faceIndex = 0}) async {
    File? tempFile;
    try {
      // EXIF 회전을 픽셀에 굽기 → ML Kit과 Image 위젯이 같은 좌표계 사용
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final oriented = img.bakeOrientation(decoded);
      final imageWidth = oriented.width.toDouble();
      final imageHeight = oriented.height.toDouble();

      final tempDir = await Directory.systemTemp.createTemp('apex_');
      tempFile = File('${tempDir.path}/oriented.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(oriented, quality: 92));

      final inputImage = InputImage.fromFile(tempFile);
      final faces = await _detector.processImage(inputImage);
      if (faces.isEmpty || faceIndex >= faces.length) return null;

      final face = faces[faceIndex];

      // 랜드마크 추출
      final leftEye = face.landmarks[FaceLandmarkType.leftEye];
      final rightEye = face.landmarks[FaceLandmarkType.rightEye];
      final nose = face.landmarks[FaceLandmarkType.noseBase];
      final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
      final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
      final leftEar = face.landmarks[FaceLandmarkType.leftEar];
      final rightEar = face.landmarks[FaceLandmarkType.rightEar];
      final leftCheek = face.landmarks[FaceLandmarkType.leftCheek];
      final rightCheek = face.landmarks[FaceLandmarkType.rightCheek];

      // 고개 각도 3축
      final headRoll  = face.headEulerAngleZ ?? 0.0; // 갸우뚱 (Z)
      final headYaw   = face.headEulerAngleY ?? 0.0; // 좌우 돌림 (Y)
      final headPitch = face.headEulerAngleX ?? 0.0; // 위아래 (X)

      // 1. 눈꼬리 각도 계산 + 다중 랜드마크 기반 head tilt 보정
      double eyeAngle = 0.0;
      String eyeAngleDesc = '수평';
      double actualHeadTilt = headRoll; // 기본값은 ML Kit headRoll

      if (leftEye != null && rightEye != null) {
        // 눈 기울기
        final eyeDx = rightEye.position.x - leftEye.position.x;
        final eyeDy = rightEye.position.y - leftEye.position.y;
        final rawEyeAngle = atan2(eyeDy, eyeDx) * 180 / pi;

        // 입꼬리 기울기 (있을 때만)
        if (leftMouth != null && rightMouth != null) {
          final mouthDx = rightMouth.position.x - leftMouth.position.x;
          final mouthDy = rightMouth.position.y - leftMouth.position.y;
          final mouthTilt = atan2(mouthDy, mouthDx) * 180 / pi;

          // 눈 기울기와 입 기울기가 같은 방향이면 → 실제 고개 기울기
          // 방향이 다르면 → 자연스러운 얼굴 비대칭 (보정 최소화)
          if ((rawEyeAngle > 0) == (mouthTilt > 0)) {
            // 같은 방향: 눈+입 평균으로 실제 tilt 추정
            actualHeadTilt = (rawEyeAngle + mouthTilt) / 2;
          } else {
            // 다른 방향: 얼굴 비대칭 가능성 → headRoll만 사용 (더 신뢰 가능)
            actualHeadTilt = headRoll;
          }
        } else {
          // 입꼬리 없으면 눈 기울기 자체가 tilt
          actualHeadTilt = rawEyeAngle;
        }

        eyeAngle = rawEyeAngle - actualHeadTilt;
        if (eyeAngle > 3) eyeAngleDesc = '올라감';
        else if (eyeAngle < -3) eyeAngleDesc = '내려감';
        else eyeAngleDesc = '수평';
      }

      // 2. 얼굴 폭/길이 비율
      double faceRatio = 0.0;
      String faceShape = '타원형';
      final faceWidth = face.boundingBox.width;
      final faceHeight = face.boundingBox.height;
      if (faceWidth > 0 && faceHeight > 0) {
        faceRatio = faceWidth / faceHeight;
        if (faceRatio > 0.85) faceShape = '둥근형';
        else if (faceRatio < 0.65) faceShape = '갸름한형';
        else faceShape = '계란형';
      }

      // 3. 눈 간격 (얼굴 폭 대비 비율)
      double eyeGapRatio = 0.0;
      String eyeGapDesc = '보통';
      if (leftEye != null && rightEye != null) {
        final eyeGap = (rightEye.position.x - leftEye.position.x).abs();
        eyeGapRatio = eyeGap / faceWidth;
        if (eyeGapRatio > 0.45) eyeGapDesc = '넓음';
        else if (eyeGapRatio < 0.35) eyeGapDesc = '좁음';
        else eyeGapDesc = '보통';
      }

      // 4. 황금비율 (이마:코:턱 비율)
      double goldenRatio = 0.0;
      String goldenDesc = '분석불가';
      if (leftEye != null && rightEye != null && nose != null && leftMouth != null) {
        final eyeY = (leftEye.position.y + rightEye.position.y) / 2;
        final mouthY = (leftMouth.position.y + (rightMouth?.position.y ?? leftMouth.position.y)) / 2;
        final foreheadToEye = eyeY - face.boundingBox.top;
        final eyeToNose = nose.position.y - eyeY;
        final noseToMouth = mouthY - nose.position.y;
        final total = foreheadToEye + eyeToNose + noseToMouth;
        if (total > 0) {
          goldenRatio = eyeToNose / total;
          if (goldenRatio > 0.28 && goldenRatio < 0.38) goldenDesc = '황금비율에 가까움';
          else if (goldenRatio > 0.38) goldenDesc = '코가 상대적으로 김';
          else goldenDesc = '코가 상대적으로 짧음';
        }
      }

      // 5. 코 폭 (얼굴 폭 대비)
      double noseWidthRatio = 0.0;
      String noseDesc = '보통';
      if (leftCheek != null && rightCheek != null && nose != null) {
        final cheekWidth = (rightCheek.position.x - leftCheek.position.x).abs();
        noseWidthRatio = faceWidth / cheekWidth;
        if (noseWidthRatio > 1.1) noseDesc = '콧볼이 넓음';
        else if (noseWidthRatio < 0.9) noseDesc = '콧볼이 좁음';
        else noseDesc = '보통';
      }

      return {
        // 수치 데이터
        'eye_angle': eyeAngle.toStringAsFixed(1),
        'eye_angle_desc': eyeAngleDesc,
        'face_shape': faceShape,
        'face_ratio': faceRatio.toStringAsFixed(2),
        'eye_gap_desc': eyeGapDesc,
        'eye_gap_ratio': eyeGapRatio.toStringAsFixed(2),
        'golden_ratio': goldenRatio.toStringAsFixed(2),
        'golden_desc': goldenDesc,
        'nose_desc': noseDesc,
        'nose_width_ratio': noseWidthRatio.toStringAsFixed(2),
        // 이미지 정보
        'image_width': imageWidth,
        'image_height': imageHeight,
        // 랜드마크 좌표 (황금비율 시각화용)
        if (leftEye != null) ...{
          'lm_left_eye_x': leftEye.position.x,
          'lm_left_eye_y': leftEye.position.y,
        },
        if (rightEye != null) ...{
          'lm_right_eye_x': rightEye.position.x,
          'lm_right_eye_y': rightEye.position.y,
        },
        if (nose != null) ...{
          'lm_nose_x': nose.position.x,
          'lm_nose_y': nose.position.y,
        },
        if (leftMouth != null) ...{
          'lm_left_mouth_x': leftMouth.position.x,
          'lm_left_mouth_y': leftMouth.position.y,
        },
        if (rightMouth != null) ...{
          'lm_right_mouth_x': rightMouth.position.x,
          'lm_right_mouth_y': rightMouth.position.y,
        },
        // 좌우 대칭도 (0~100, 높을수록 대칭)
        'symmetry_score': _calcSymmetry(
          face.boundingBox.left, face.boundingBox.right,
          leftEye?.position.x.toDouble(), rightEye?.position.x.toDouble(),
          leftMouth?.position.x.toDouble(), rightMouth?.position.x.toDouble(),
          nose?.position.x.toDouble(),
        ),
        // 얼굴 바운딩박스
        'bb_left': face.boundingBox.left,
        'bb_top': face.boundingBox.top,
        'bb_right': face.boundingBox.right,
        'bb_bottom': face.boundingBox.bottom,
        // 고개 기울기
        'head_tilt': actualHeadTilt.toStringAsFixed(1),
        'head_yaw': headYaw.toStringAsFixed(1),
        'head_pitch': headPitch.toStringAsFixed(1),
        // 실제 추정 기울기 기준으로 경고
        'head_tilt_warning': actualHeadTilt.abs() > 12 || headYaw.abs() > 15,
        'head_warn_type': headYaw.abs() > 15
            ? 'yaw'
            : actualHeadTilt.abs() > 12 ? 'roll' : 'none',
        // yaw 보정된 얼굴 비율 (고개 돌림 왜곡 제거)
        ..._classifyFaceTypeDetailed(
          eyeAngle: eyeAngle,
          faceRatio: faceRatio,
          eyeGapRatio: eyeGapRatio,
          headYaw: headYaw,
          goldenRatio: goldenRatio,
          noseWidthRatio: noseWidthRatio,
        ),
      };
    } catch (e) {
      return null;
    } finally {
      await tempFile?.parent.delete(recursive: true);
    }
  }

  // 좌우 대칭도 계산 (0~100)
  static int _calcSymmetry(
    double bbLeft, double bbRight,
    double? leX, double? reX,
    double? lmX, double? rmX,
    double? noseX,
  ) {
    final cx = (bbLeft + bbRight) / 2;
    final faceW = bbRight - bbLeft;
    if (faceW <= 0) return 80;

    final errors = <double>[];

    // 눈: 중심 기준 좌우 거리 차이
    if (leX != null && reX != null) {
      final lDist = (cx - leX).abs();
      final rDist = (reX - cx).abs();
      errors.add((lDist - rDist).abs() / faceW);
    }

    // 입꼬리: 중심 기준 좌우 거리 차이
    if (lmX != null && rmX != null) {
      final lDist = (cx - lmX).abs();
      final rDist = (rmX - cx).abs();
      errors.add((lDist - rDist).abs() / faceW);
    }

    // 코: 중심에 가까울수록 대칭
    if (noseX != null) {
      errors.add((noseX - cx).abs() / faceW * 2);
    }

    if (errors.isEmpty) return 80;
    final avgError = errors.reduce((a, b) => a + b) / errors.length;
    return (100 - (avgError * 300).clamp(0, 35)).round();
  }

  // 동물상 분류 + 전체 점수 맵 반환 (yaw 보정 포함)
  static Map<String, dynamic> _classifyFaceTypeDetailed({
    required double eyeAngle,
    required double faceRatio,
    required double eyeGapRatio,
    double headYaw = 0.0,
    double goldenRatio = 0.33,
    double noseWidthRatio = 1.0,
  }) {
    // Yaw 보정: 고개가 돌아가면 얼굴이 좁아 보임 → 보정
    final yawRad = headYaw.abs() * pi / 180;
    final correctedFaceRatio = yawRad > 0.05
        ? (faceRatio / cos(yawRad)).clamp(0.5, 1.1)
        : faceRatio;

    final scores = {
      '강아지상': 0.0,
      '고양이상': 0.0,
      '곰상': 0.0,
      '늑대상': 0.0,
      '여우상': 0.0,
    };

    // 1. 눈꼬리 각도 (가중치 높음 — 표정 영향 적음)
    if (eyeAngle > 5) {
      scores['고양이상'] = scores['고양이상']! + 3;
      scores['여우상'] = scores['여우상']! + 3;
      scores['늑대상'] = scores['늑대상']! + 1;
    } else if (eyeAngle > 2) {
      scores['고양이상'] = scores['고양이상']! + 2;
      scores['여우상'] = scores['여우상']! + 2;
      scores['늑대상'] = scores['늑대상']! + 1;
    } else if (eyeAngle < -5) {
      scores['강아지상'] = scores['강아지상']! + 3;
      scores['곰상'] = scores['곰상']! + 2;
    } else if (eyeAngle < -2) {
      scores['강아지상'] = scores['강아지상']! + 2;
      scores['곰상'] = scores['곰상']! + 1;
    } else {
      scores['늑대상'] = scores['늑대상']! + 2;
      scores['강아지상'] = scores['강아지상']! + 1;
    }

    // 2. 얼굴 비율 (yaw 보정 적용)
    if (correctedFaceRatio > 0.85) {
      scores['곰상'] = scores['곰상']! + 3;
      scores['강아지상'] = scores['강아지상']! + 2;
      scores['고양이상'] = scores['고양이상']! - 1;
      scores['늑대상'] = scores['늑대상']! - 1;
    } else if (correctedFaceRatio < 0.65) {
      scores['늑대상'] = scores['늑대상']! + 3;
      scores['고양이상'] = scores['고양이상']! + 2;
      scores['여우상'] = scores['여우상']! + 2;
      scores['곰상'] = scores['곰상']! - 1;
    } else {
      scores['강아지상'] = scores['강아지상']! + 1;
      scores['고양이상'] = scores['고양이상']! + 1;
      scores['늑대상'] = scores['늑대상']! + 1;
    }

    // 3. 눈 간격
    if (eyeGapRatio > 0.45) {
      scores['강아지상'] = scores['강아지상']! + 2;
      scores['곰상'] = scores['곰상']! + 2;
    } else if (eyeGapRatio < 0.35) {
      scores['고양이상'] = scores['고양이상']! + 2;
      scores['여우상'] = scores['여우상']! + 2;
      scores['늑대상'] = scores['늑대상']! + 1;
    } else {
      scores['강아지상'] = scores['강아지상']! + 1;
    }

    // 4. 황금비율 (코 길이 비율) — 가중치: 중간
    // 0.28~0.38: 이상적. 낮을수록 코가 짧음(강아지/곰상), 높을수록 코가 김(늑대/여우상)
    if (goldenRatio > 0.38) {
      scores['늑대상'] = scores['늑대상']! + 2;
      scores['여우상'] = scores['여우상']! + 1;
    } else if (goldenRatio < 0.28) {
      scores['강아지상'] = scores['강아지상']! + 2;
      scores['곰상'] = scores['곰상']! + 1;
    }

    // 5. 코 폭 비율 (콧볼 넓이) — 가중치: 낮음
    // noseWidthRatio > 1.1: 콧볼 넓음 → 강아지/곰상
    // noseWidthRatio < 0.9: 콧볼 좁음 → 고양이/여우/늑대상
    if (noseWidthRatio > 1.1) {
      scores['강아지상'] = scores['강아지상']! + 1;
      scores['곰상'] = scores['곰상']! + 1;
    } else if (noseWidthRatio < 0.9) {
      scores['고양이상'] = scores['고양이상']! + 1;
      scores['여우상'] = scores['여우상']! + 1;
      scores['늑대상'] = scores['늑대상']! + 1;
    }

    // 점수를 0~100 퍼센트로 변환
    final minScore = scores.values.reduce(min);
    final shifted = scores.map((k, v) => MapEntry(k, v - minScore));
    final total = shifted.values.reduce((a, b) => a + b);
    final pct = total > 0
        ? shifted.map((k, v) => MapEntry(k, (v / total * 100).round()))
        : scores.map((k, _) => MapEntry(k, 20));

    // 1위 결정
    final sorted = pct.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final first = sorted[0];
    final second = sorted[1];

    // 경계선 처리: 1~2위 차이 10점 미만이면 계열 표시
    final isCloseCall = (first.value - second.value) <= 10;
    final displayType = first.key;
    final secondType = isCloseCall ? second.key : null;

    return {
      'current_face_type': displayType,
      'face_type_second': secondType,
      'face_type_is_borderline': isCloseCall,
      'face_type_scores': pct,
      // 보정된 얼굴 비율도 저장
      'face_ratio_corrected': correctedFaceRatio.toStringAsFixed(2),
    };
  }

  static void dispose() {
    _detector.close();
  }
}