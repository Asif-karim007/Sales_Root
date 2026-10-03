/// Cards and QR codes the fake reader returns in turn, shaped like the
/// Gemini reply.
const cardScanFixtures = <Map<String, dynamic>>[
  {
    'contactName': 'Md. Karim',
    'designation': 'Purchase Manager',
    'companyName': 'Karim Textiles Ltd.',
    'phones': ['+880 1711-234567'],
    'emails': ['karim@karimtex.com'],
    'website': 'www.karimtex.com',
    'address': 'House 12, Road 3, Mirpur DOHS, Dhaka',
    'unclearFields': <String>[],
  },
  {
    'contactName': 'Nusrat Jahan',
    'designation': 'Head of Procurement',
    'companyName': 'Orion Agro Processing Ltd.',
    'department': 'Supply Chain',
    'phones': ['+880 1819-445210', '+880 2-9881234'],
    'emails': ['nusrat.j@orionagro.com.bd'],
    'address': 'Plot 7, BSCIC I/A, Narayanganj',
    'unclearFields': ['emails'],
  },
  {
    'contactName': 'Engr. Shafiqul Alam',
    'designation': 'Factory Manager',
    'companyName': 'Shapla Garments',
    'phones': ['01713-90 2286'],
    'emails': <String>[],
    'address': 'Konabari, Gazipur',
    'unclearFields': ['phones', 'address'],
  },
  {
    'contactName': 'মোঃ রাশেদুল হক',
    'designation': 'প্রোপাইটর',
    'companyName': 'হক ট্রেডার্স',
    'phones': ['০১৯১১-৩৪৫৬৭৮'],
    'emails': <String>[],
    'address': 'জিনজিরা, কেরানীগঞ্জ, ঢাকা',
    'unclearFields': ['designation'],
  },
  {
    'contactName': 'Tahmina Akter',
    'designation': 'Admin Officer',
    'companyName': 'Bengal Steel',
    'phones': ['+880 1552-118899'],
    'emails': ['tahmina@bengalsteel.com'],
    'website': 'bengalsteel.com',
    'address': 'Tejgaon I/A, Dhaka 1208',
    'unclearFields': <String>[],
  },
];

const qrScanFixtures = [
  'https://karimtex.com/catalog/2026',
  'BEGIN:VCARD\nVERSION:3.0\nFN:Rezaul Karim\nTITLE:Accounts Manager\n'
      'ORG:Meghna Group\nTEL;TYPE=CELL:+8801715667788\n'
      'EMAIL:rezaul@meghnagroup.com\nADR:;;Motijheel C/A;Dhaka;;1000;\n'
      'END:VCARD',
  'WIFI:T:WPA;S:DeltaPower-Guest;P:solar2026;;',
];
