class MasterCategory {
  final String id;
  final String name;
  final String iconName;
  final int bgColor;
  final int primaryColor;
  final String description;
  final List<String> popularParts;
  final String? imageUrl;

  const MasterCategory({
    required this.id,
    required this.name,
    this.iconName = 'category',
    this.bgColor = 0xFFEFF6FF,
    this.primaryColor = 0xFF0075FF,
    this.description = '',
    this.popularParts = const [],
    this.imageUrl,
  });
}

typedef CategoryData = MasterCategory;

const List<MasterCategory> MASTER_CATEGORIES = [
  MasterCategory(
    id: 'Engine & Mechanical',
    name: 'Engine & Mechanical',
    iconName: 'engine',
    bgColor: 0xFFFEF2F2,
    primaryColor: 0xFFDC2626,
    description: 'Engines, cylinder heads, pistons, turbochargers, alternators & starters',
    popularParts: [
      'Complete Engine Assembly',
      'Cylinder Head',
      'Piston & Connecting Rods',
      'Turbocharger / Intercooler',
      'Alternator',
      'Starter Motor',
    ],
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828857/categories/v40ctc1xzsul1nmquwno.png',
  ),
  MasterCategory(
    id: 'Body & Exterior',
    name: 'Body & Exterior',
    iconName: 'car_door',
    bgColor: 0xFFF0F9FF,
    primaryColor: 0xFF0284C7,
    description: 'Bumpers, bonnets, grilles, doors, fenders, boot lids & mirrors',
    popularParts: [
      'Front Bumper Assembly',
      'Rear Bumper Assembly',
      'Bonnet / Hood',
      'Front Grille',
      'Side Mirror Assembly (ORVM)',
      'Front / Rear Doors',
    ],
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788915211/categories/ssxl1agf8ydkau5aqv4h.png',
  ),
  MasterCategory(
    id: 'Lights & Electricals',
    name: 'Lights & Electricals',
    iconName: 'flash',
    bgColor: 0xFFFEFCE8,
    primaryColor: 0xFFCA8A04,
    description: 'Headlights, tail lights, fog lamps, sensors, ECU & wiring kits',
    popularParts: [
      'Headlight Assembly (Pair / Single)',
      'Tail Light Assembly',
      'Fog Light Kit',
      'ECU / Engine Control Module',
      'Instrument Cluster / Speedometer',
      'Alternator / Battery Cable',
    ],
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828859/categories/aeyy5x1q4jyl7tw4a9n4.png',
  ),
  MasterCategory(
    id: 'Brakes & Suspension',
    name: 'Brakes & Suspension',
    iconName: 'disc_brake',
    bgColor: 0xFFF0FDF4,
    primaryColor: 0xFF16A34A,
    description: 'Shock absorbers, brake calipers, discs, steering racks & springs',
    popularParts: [
      'Front Shock Absorbers / Struts',
      'Rear Shock Absorbers',
      'Brake Disc Rotors & Calipers',
      'Steering Rack Assembly',
      'Control Arms / Wishbone',
      'ABS Module / Wheel Speed Sensor',
    ],
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828857/categories/k2r8d3o23j4u4w657d4b.png',
  ),
  MasterCategory(
    id: 'Interior & Cabin',
    name: 'Interior & Cabin',
    iconName: 'seat',
    bgColor: 0xFFFAF5FF,
    primaryColor: 0xFF9333EA,
    description: 'Steering wheels, infotainment, dashboards, seat sets & AC vents',
    popularParts: [
      'Steering Wheel & Airbag',
      'Touchscreen Infotainment System',
      'AC Compressor & Cooling Coil',
      'Dashboard Assembly',
      'Power Window Switches & Motors',
      'Seat Sets & Covers',
    ],
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828858/categories/p4kkmj31m5l7p0g3t4k4.png',
  ),
  MasterCategory(
    id: 'Wheels & Tyres',
    name: 'Wheels & Tyres',
    iconName: 'wheel',
    bgColor: 0xFFFFF7ED,
    primaryColor: 0xFFEA580C,
    description: 'Alloy wheels, steel rims, hubcaps, spare tyres & TPM sensors',
    popularParts: [
      'OEM Alloy Wheels (Set of 4)',
      'Single Spare Alloy Wheel',
      'Steel Rims',
      'Tyres (Radial / Tubeless)',
      'Wheel Hub & Bearings',
      'TPMS Sensors',
    ],
    imageUrl: 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828859/categories/b5kmj21m5l7p0g3t4k4.png',
  ),
];

const List<Map<String, dynamic>> TOP_BRANDS = [
  {'name': 'Maruti Suzuki', 'logo': 'maruti_suzuki'},
  {'name': 'Hyundai', 'logo': 'hyundai'},
  {'name': 'Tata', 'logo': 'tata'},
  {'name': 'Mahindra', 'logo': 'mahindra'},
  {'name': 'Toyota', 'logo': 'toyota'},
  {'name': 'Honda', 'logo': 'honda'},
  {'name': 'Kia', 'logo': 'kia'},
  {'name': 'Volkswagen', 'logo': 'volkswagen'},
  {'name': 'Ford', 'logo': 'ford'},
  {'name': 'Skoda', 'logo': 'skoda'},
  {'name': 'Renault', 'logo': 'renault'},
  {'name': 'BMW', 'logo': 'bmw'},
  {'name': 'Audi', 'logo': 'audi'},
  {'name': 'Mercedes', 'logo': 'mercedes'},
];
