import 'package:salesroot/core/fake/seed_graph.dart';

/// The catalogue as the server sends it: the seed products with Bangla names,
/// VAT and stock (services carry none).
List<Map<String, dynamic>> productFixtures(SeedGraph graph) {
  final random = graph.random('products');
  return [
    for (final product in graph.products)
      {
        'Id': product.id,
        'Code': product.code,
        'Name': product.name,
        'NameBn': productNameBn(product.code),
        'Category': product.category,
        'Unit': product.unit,
        'Price': product.price,
        'DealerPrice': product.dealerPrice,
        'VatBps': 1500,
        'Stock': product.category == 'Services'
            ? null
            : switch (random.nextInt(10)) {
                0 => 0,
                1 || 2 => 2 + random.nextInt(6),
                _ => 10 + random.nextInt(60),
              },
      },
  ];
}

String productNameBn(String code) => _bangla[code] ?? '';

const Map<String, String> _bangla = {
  'SP-550': 'সোলার প্যানেল ৫৫০W',
  'SP-450': 'সোলার প্যানেল ৪৫০W',
  'SP-330': 'সোলার প্যানেল ৩৩০W',
  'SP-200': 'সোলার প্যানেল ২০০W',
  'SP-100': 'সোলার প্যানেল ১০০W',
  'IV-3K': 'হাইব্রিড ইনভার্টার ৩kW',
  'IV-5K': 'হাইব্রিড ইনভার্টার ৫kW',
  'IV-8K': 'হাইব্রিড ইনভার্টার ৮kW',
  'IV-10K': 'অন-গ্রিড ইনভার্টার ১০kW',
  'IV-1K': 'হোম আইপিএস ১kVA',
  'BT-5': 'লিথিয়াম ব্যাটারি ৫kWh',
  'BT-10': 'লিথিয়াম ব্যাটারি ১০kWh',
  'BT-200': 'টিউবুলার ব্যাটারি ২০০Ah',
  'BT-150': 'টিউবুলার ব্যাটারি ১৫০Ah',
  'CB-4': 'সোলার ডিসি ক্যাবল ৪mm²',
  'CB-6': 'সোলার ডিসি ক্যাবল ৬mm²',
  'MC-4': 'MC4 কানেক্টর জোড়া',
  'MS-R': 'ছাদের মাউন্টিং স্ট্রাকচার',
  'MS-G': 'মাটির মাউন্টিং স্ট্রাকচার',
  'CC-60': 'MPPT চার্জ কন্ট্রোলার ৬০A',
  'DB-1': 'ডিসি কম্বাইনার বক্স',
  'SA-1': 'সার্জ অ্যারেস্টার',
  'EM-1': 'স্মার্ট এনার্জি মিটার',
  'WF-1': 'Wi-Fi মনিটরিং ডঙ্গল',
  'SL-60': 'সোলার স্ট্রিট লাইট ৬০W',
  'SL-30': 'সোলার স্ট্রিট লাইট ৩০W',
  'FL-100': 'LED ফ্লাড লাইট ১০০W',
  'PM-1': 'সোলার পানির পাম্প ১HP',
  'PM-2': 'সোলার পানির পাম্প ২HP',
  'SV-INS': 'ইনস্টলেশন সার্ভিস',
  'SV-SUR': 'সাইট সার্ভে',
  'SV-AMC': 'বার্ষিক রক্ষণাবেক্ষণ চুক্তি',
  'SV-CLN': 'প্যানেল পরিষ্কার',
  'SV-NM': 'নেট মিটারিং কাগজপত্র',
  'SV-TRN': 'অপারেটর ট্রেনিং',
  'SV-EXT': 'বর্ধিত ওয়ারেন্টি ৫ বছর',
  'KT-1': 'হোম সোলার কিট ১kW',
  'KT-3': 'হোম সোলার কিট ৩kW',
  'KT-5': 'অফিস সোলার কিট ৫kW',
  'KT-10': 'ফ্যাক্টরি সোলার কিট ১০kW',
  'BT-RK': 'ব্যাটারি র‍্যাক',
  'EA-1': 'আর্থিং কিট',
};
