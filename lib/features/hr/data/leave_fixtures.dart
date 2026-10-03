import 'package:salesroot/core/fake/seed_graph.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/hr/data/hr_people.dart';
import 'package:salesroot/features/hr/models/leave.dart';

const int casualLeaveId = 1;
const int sickLeaveId = 2;
const int annualLeaveId = 3;
const int unpaidLeaveId = 4;

const List<Map<String, dynamic>> leaveTypeRows = [
  {
    'Id': casualLeaveId,
    'Name': 'Casual',
    'NameBn': 'নৈমিত্তিক',
    'Entitlement': 10,
  },
  {'Id': sickLeaveId, 'Name': 'Sick', 'NameBn': 'অসুস্থতা', 'Entitlement': 14},
  {
    'Id': annualLeaveId,
    'Name': 'Annual',
    'NameBn': 'বার্ষিক',
    'Entitlement': 15,
  },
  {
    'Id': unpaidLeaveId,
    'Name': 'Unpaid',
    'NameBn': 'বিনা বেতনে',
    'Entitlement': 0,
    'IsPaid': false,
  },
];

Map<String, dynamic> leaveTypeRow(int id) =>
    leaveTypeRows.firstWhere((row) => row['Id'] == id);

/// A leave row as the server stores it. Dates are local midnights.
Map<String, dynamic> leaveRow({
  required SeedGraph graph,
  required int id,
  required int employeeId,
  required int typeId,
  required DateTime start,
  required DateTime end,
  required int statusId,
  required DateTime appliedAt,
  bool halfDay = false,
  String? reason,
  String? remarks,
  String? attachment,
}) {
  final employee = memberOrNull(graph, employeeId);
  final approver = approverOf(graph, employeeId);
  final type = leaveTypeRow(typeId);
  final decided = statusId != LeaveStatusRef.pending;
  return {
    'Id': id,
    'EmployeeId': employeeId,
    ...personFields('EmployeeName', employee),
    'Designation': employee?.designation,
    'LeaveTypeId': typeId,
    'LeaveTypeName': type['Name'],
    'LeaveTypeNameBn': type['NameBn'],
    'StartDate': jsonUtc(start),
    'EndDate': jsonUtc(end),
    'NoOfDays': leaveDays(start, end, halfDay: halfDay),
    'Reason': reason,
    'Remarks': remarks,
    'StatusId': statusId,
    'AppliedAt': jsonUtc(appliedAt),
    if (decided) 'StatusUpdatedAt': jsonUtc(appliedAt.add(_decisionDelay)),
    if (decided) ...personFields('ApproverName', approver),
    ...personFields('CoverName', coverOf(graph, employeeId)),
    if (attachment != null) 'Attachment': {'FileName': attachment},
  }..removeWhere((_, value) => value == null);
}

const _decisionDelay = Duration(hours: 5);

/// A teammate under the same manager who takes the visits while away.
SeedMember? coverOf(SeedGraph graph, int employeeId) {
  final managerId = memberOrNull(graph, employeeId)?.managerId;
  if (managerId == null) return null;
  return graph.members
      .where((m) => m.managerId == managerId && m.id != employeeId)
      .firstOrNull;
}

List<Map<String, dynamic>> leaveFixtures(SeedGraph graph) {
  final rows = <Map<String, dynamic>>[];
  var id = 1;
  DateTime day(int offset) {
    final date = graph.daysAhead(offset, hour: 0);
    return date.weekday == DateTime.friday
        ? DateTime(date.year, date.month, date.day + 1)
        : date;
  }

  void add(
    int employeeId,
    int typeId,
    int from,
    int to,
    int statusId, {
    bool halfDay = false,
    String? reason,
    String? remarks,
    String? attachment,
  }) {
    rows.add(
      leaveRow(
        graph: graph,
        id: id++,
        employeeId: employeeId,
        typeId: typeId,
        start: day(from),
        end: day(to),
        statusId: statusId,
        appliedAt: graph.daysAhead(from - 4, hour: 11, minute: 20),
        halfDay: halfDay,
        reason: reason,
        remarks: remarks,
        attachment: attachment,
      ),
    );
  }

  final me = SeedGraph.meId;
  add(
    me,
    annualLeaveId,
    24,
    26,
    LeaveStatusRef.pending,
    reason: 'Eid-er chhuti, family niye Sylhet jabo',
  );
  add(
    me,
    casualLeaveId,
    -15,
    -15,
    LeaveStatusRef.approved,
    reason: 'বাসা বদল — shifting to Mirpur 10',
  );
  add(
    me,
    sickLeaveId,
    -22,
    -21,
    LeaveStatusRef.approved,
    reason: 'জ্বর, doctor said 2 days rest',
    attachment: 'prescription.jpg',
  );
  add(
    me,
    unpaidLeaveId,
    -30,
    -30,
    LeaveStatusRef.approved,
    reason: 'Village land registry office',
  );
  add(
    me,
    casualLeaveId,
    -41,
    -40,
    LeaveStatusRef.approved,
    reason: 'Sister-er biye, Comilla',
  );
  add(
    me,
    annualLeaveId,
    -62,
    -58,
    LeaveStatusRef.rejected,
    reason: 'Cox’s Bazar trip',
    remarks: 'Quarter closing week — please take it next month',
  );
  add(
    me,
    casualLeaveId,
    -75,
    -75,
    LeaveStatusRef.approved,
    halfDay: true,
    reason: 'Bank-e kaj, afternoon only',
  );

  final random = graph.random('leave');
  final others = graph.members.where((m) => m.id != me).toList();
  for (final member in others) {
    final count = 1 + random.nextInt(3);
    for (var i = 0; i < count; i++) {
      final ahead = i == 0 && random.nextInt(3) == 0;
      final start = ahead ? 2 + random.nextInt(20) : -(5 + random.nextInt(80));
      final length = random.nextInt(3);
      final typeId = [
        casualLeaveId,
        casualLeaveId,
        sickLeaveId,
        annualLeaveId,
        unpaidLeaveId,
      ][random.nextInt(5)];
      final statusId = ahead && approverOf(graph, member.id) != null
          ? LeaveStatusRef.pending
          : (random.nextInt(6) == 0
                ? LeaveStatusRef.rejected
                : LeaveStatusRef.approved);
      add(
        member.id,
        typeId,
        start,
        start + length,
        statusId,
        halfDay: length == 0 && random.nextInt(4) == 0,
        reason: _reasons[random.nextInt(_reasons.length)],
        remarks: statusId == LeaveStatusRef.rejected
            ? _rejections[random.nextInt(_rejections.length)]
            : null,
      );
    }
  }
  return rows;
}

const List<String> _reasons = [
  'গ্রামে পারিবারিক অনুষ্ঠান',
  'Family event in the village',
  'জ্বর আর ঠান্ডা',
  'Child’s school admission test',
  'Mother is in hospital, Mymensingh',
  'বিয়ের দাওয়াত, Rajshahi',
  'Dental surgery — Banani',
  'Passport renewal appointment',
  'বাড়ি যাচ্ছি, Eid-er age',
  'Personal work, half day enough',
];

const List<String> _rejections = [
  'Delta Power installation that week — need you on site',
  'Too many people off that day, please shift by a week',
  'অডিট চলছে, পরের সপ্তাহে নিন',
];
