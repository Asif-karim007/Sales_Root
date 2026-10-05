import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/contacts/models/company.dart';
import 'package:salesroot/features/contacts/models/contact.dart';
import 'package:salesroot/features/contacts/models/customer.dart';
import 'package:salesroot/features/contacts/models/linked_records.dart';

/// `GET companies/{id}`: the company with its people, leads, orders,
/// payments, activity and files.
class CompanyDetail {
  const CompanyDetail({
    required this.company,
    this.people = const [],
    this.leads = const [],
    this.orders = const [],
    this.payments = const [],
    this.activities = const [],
    this.documents = const [],
  });

  final Company company;
  final List<Contact> people;
  final List<LinkedLead> leads;
  final List<SalesDocRef> orders;
  final List<CustomerPayment> payments;
  final List<ContactActivity> activities;
  final List<CustomerDocument> documents;

  factory CompanyDetail.fromJson(Map<String, dynamic> json) {
    final company = Company.fromJson(jsonMap(json['company']));
    return CompanyDetail(
      company: company,
      people: [
        for (final person in jsonList(json['people'], Contact.fromJson))
          Contact(
            id: person.id,
            name: person.name,
            designation: person.designation,
            companyId: company.id,
            companyName: company.name,
            mobiles: person.mobiles,
            emails: person.emails,
          ),
      ],
      leads: jsonList(json['leads'], LinkedLead.fromJson),
      orders: jsonList(json['orders'], SalesDocRef.fromOrder),
      payments: jsonList(json['payments'], CustomerPayment.fromJson),
      activities: jsonList(json['timeline'], ContactActivity.fromJson),
      documents: jsonList(json['files'], CustomerDocument.fromJson),
    );
  }
}

/// `GET contacts/{id}`: the contact with their leads and activity.
class ContactDetail {
  const ContactDetail({
    required this.contact,
    this.leads = const [],
    this.activities = const [],
  });

  final Contact contact;
  final List<LinkedLead> leads;
  final List<ContactActivity> activities;

  factory ContactDetail.fromJson(Map<String, dynamic> json) => ContactDetail(
    contact: Contact.fromJson(jsonMap(json['contact'])),
    leads: jsonList(json['leads'], LinkedLead.fromJson),
    activities: jsonList(json['timeline'], ContactActivity.fromJson),
  );
}
