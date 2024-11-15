import 'package:get/get.dart';

class StudentMarksController extends GetxController {
  final RxList<StudentMark> marks = <StudentMark>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadStudentMarks();
  }

  void loadStudentMarks() {
    marks.value = [
      StudentMark('Aburaya', 85),
      StudentMark('Sami', 92),
      StudentMark('Ali', 78),
      StudentMark('Nader', 88),
      StudentMark('Omar', 95),
      StudentMark('Bakr', 82),
    ];
  }
}

class StudentMark {
  final String name;
  final double score;

  StudentMark(this.name, this.score);
}
