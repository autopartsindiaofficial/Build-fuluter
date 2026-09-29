import sharp from 'sharp';
import fs from 'fs';
import path from 'path';

// 1. Master Auto Parts India Full Logo SVG (Car + Gear + Wrench + "Auto parts India" + "BUY • SELL • FIND • AUTO PARTS")
export const MASTER_LOGO_SVG = `
<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- Gear Blue Gradients -->
    <linearGradient id="gearGradient" x1="512" y1="60" x2="512" y2="720" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#0080FF"/>
      <stop offset="40%" stop-color="#0060E6"/>
      <stop offset="100%" stop-color="#0035A8"/>
    </linearGradient>
    <linearGradient id="gearBevel" x1="120" y1="60" x2="904" y2="720" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#38B6FF"/>
      <stop offset="50%" stop-color="#0066FF"/>
      <stop offset="100%" stop-color="#002277"/>
    </linearGradient>

    <!-- Windshield Gradient -->
    <linearGradient id="windshieldGrad" x1="512" y1="300" x2="512" y2="440" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#004BBB"/>
      <stop offset="100%" stop-color="#002166"/>
    </linearGradient>

    <!-- Headlight Cyan Glow -->
    <linearGradient id="lightGlow" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#00F0FF"/>
      <stop offset="100%" stop-color="#0088FF"/>
    </linearGradient>

    <!-- Wrench Chrome & Blue Swoosh -->
    <linearGradient id="wrenchChrome" x1="200" y1="520" x2="880" y2="680" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#E2E8F0"/>
      <stop offset="50%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#CBD5E1"/>
    </linearGradient>
    <linearGradient id="swooshGrad" x1="140" y1="520" x2="750" y2="700" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#00E5FF"/>
      <stop offset="50%" stop-color="#0080FF"/>
      <stop offset="100%" stop-color="#0052CC"/>
    </linearGradient>

    <!-- Shadow filters -->
    <filter id="dropShadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="12" stdDeviation="16" flood-color="#001844" flood-opacity="0.35"/>
    </filter>
  </defs>

  <!-- ==================== TOP GEAR & CAR BADGE ==================== -->
  <g filter="url(#dropShadow)">
    <!-- 8-Teeth Heavy Mechanical Gear Outer Rim -->
    <path d="
      M 442,70 L 582,70 L 594,152 Q 644,166 690,192 L 766,144 L 848,226 L 800,302 Q 826,348 840,398 L 922,410 L 922,550 L 840,562 Q 826,612 800,658 L 848,734 L 766,816 L 690,768 Q 644,794 594,808 L 582,890 L 442,890 L 430,808 Q 380,794 334,768 L 258,816 L 176,734 L 224,658 Q 198,612 184,562 L 102,550 L 102,410 L 184,398 Q 198,348 224,302 L 176,226 L 258,144 L 334,192 Q 380,166 430,152 Z"
      fill="url(#gearGradient)"
      stroke="url(#gearBevel)"
      stroke-width="10"
      stroke-linejoin="round"
    />

    <!-- Inner Dark Gear Groove -->
    <circle cx="512" cy="480" r="340" fill="#04122C" stroke="#0055D4" stroke-width="8"/>

    <!-- Inner Gear Tooth Highlights -->
    <circle cx="512" cy="480" r="322" fill="#0A224A"/>

    <!-- Car Shield White Base -->
    <path d="M 230,460 C 230,300 330,200 512,200 C 694,200 794,300 794,460 C 794,620 680,680 512,680 C 344,680 230,620 230,460 Z" fill="#F8FAFC"/>

    <!-- ==================== FRONT VIEW CAR ==================== -->
    <!-- Car Cabin Roof & Pillars -->
    <path d="M 330,390 L 375,285 C 390,265 425,255 512,255 C 599,255 634,265 649,285 L 694,390 Z" fill="#0B1A30"/>
    
    <!-- Windshield -->
    <path d="M 345,385 L 386,290 C 400,274 430,268 512,268 C 594,268 624,274 638,290 L 679,385 Z" fill="url(#windshieldGrad)"/>
    
    <!-- Windshield Reflection -->
    <path d="M 400,285 L 370,380 L 420,380 L 450,285 Z" fill="#38B6FF" opacity="0.35"/>
    <path d="M 470,285 L 450,380 L 485,380 L 505,285 Z" fill="#FFFFFF" opacity="0.2"/>

    <!-- Rearview Mirrors -->
    <path d="M 328,368 C 300,368 288,382 300,396 C 314,408 335,404 340,392 Z" fill="#F1F5F9" stroke="#0B1A30" stroke-width="4"/>
    <path d="M 696,368 C 724,368 736,382 724,396 C 710,408 689,404 684,392 Z" fill="#F1F5F9" stroke="#0B1A30" stroke-width="4"/>

    <!-- Car Body Hood & Fenders (White Crisp Aerodynamic Shell) -->
    <path d="
      M 335,392 
      C 270,402 210,442 200,495 
      C 192,540 215,580 260,600 
      L 310,612 
      C 370,622 654,622 714,612 
      L 764,600 
      C 809,580 832,540 824,495 
      C 814,442 754,402 689,392 
      C 630,385 394,385 335,392 Z" 
      fill="#FFFFFF" 
      stroke="#0B1A30" 
      stroke-width="8"
    />

    <!-- Hood Sculpt Lines -->
    <path d="M 380,395 C 410,440 420,470 425,480" stroke="#CBD5E1" stroke-width="5" stroke-linecap="round"/>
    <path d="M 644,395 C 614,440 604,470 599,480" stroke="#CBD5E1" stroke-width="5" stroke-linecap="round"/>

    <!-- Front Grille -->
    <path d="M 358,476 C 358,472 370,468 512,468 C 654,468 666,472 666,476 L 650,544 C 646,554 630,558 512,558 C 394,558 378,554 374,544 Z" fill="#081426" stroke="#0F2442" stroke-width="6"/>
    <!-- Grille Chrome Horizontal Slats -->
    <path d="M 374,488 Q 512,485 650,488" stroke="#38B6FF" stroke-width="4" opacity="0.9"/>
    <path d="M 378,506 Q 512,503 646,506" stroke="#FFFFFF" stroke-width="3.5" opacity="0.85"/>
    <path d="M 384,524 Q 512,521 640,524" stroke="#38B6FF" stroke-width="4" opacity="0.9"/>
    <path d="M 394,542 Q 512,540 630,542" stroke="#CBD5E1" stroke-width="3" opacity="0.7"/>

    <!-- Left Projector LED Headlight -->
    <path d="M 230,462 C 265,462 330,470 342,504 C 330,514 265,518 226,494 C 218,480 220,468 230,462 Z" fill="#09182E" stroke="#0044BB" stroke-width="4"/>
    <path d="M 238,472 C 270,474 320,482 330,500 C 300,508 260,506 238,490 Z" fill="url(#lightGlow)"/>
    <ellipse cx="282" cy="486" rx="14" ry="6" fill="#FFFFFF"/>

    <!-- Right Projector LED Headlight -->
    <path d="M 794,462 C 759,462 694,470 682,504 C 694,514 759,518 798,494 C 806,480 804,468 794,462 Z" fill="#09182E" stroke="#0044BB" stroke-width="4"/>
    <path d="M 786,472 C 754,474 704,482 694,500 C 724,508 764,506 786,490 Z" fill="url(#lightGlow)"/>
    <ellipse cx="742" cy="486" rx="14" ry="6" fill="#FFFFFF"/>

    <!-- Lower Bumper Intake & Fog Light Accents -->
    <path d="M 270,555 L 320,555 L 310,580 L 255,575 Z" fill="#081426"/>
    <path d="M 274,566 L 312,566" stroke="#00E5FF" stroke-width="3"/>
    <path d="M 754,555 L 704,555 L 714,580 L 769,575 Z" fill="#081426"/>
    <path d="M 750,566 L 712,566" stroke="#00E5FF" stroke-width="3"/>

    <!-- ==================== SWEEPING WRENCH & SPEED TRAIL ==================== -->
    <!-- Cyan / Blue Swoosh Trail Under Wrench -->
    <path d="
      M 150,520
      C 140,580 180,670 290,710
      C 410,755 640,730 790,670
      C 730,695 560,735 400,715
      C 270,698 175,640 150,520 Z"
      fill="url(#swooshGrad)"
    />

    <!-- Sweeping Mechanical Chrome Wrench -->
    <path d="
      M 170,535
      C 165,600 230,675 360,695
      C 510,718 690,668 780,610
      L 776,570
      C 790,560 820,530 860,530
      C 900,530 930,560 935,595
      C 940,630 920,665 885,685
      C 860,700 810,710 780,708
      C 670,750 480,755 330,725
      C 220,702 155,625 170,535 Z"
      fill="url(#wrenchChrome)"
      stroke="#0B1A30"
      stroke-width="7"
      stroke-linejoin="round"
    />

    <!-- Wrench Head Jaws Cutout -->
    <path d="
      M 865,532
      C 845,550 840,575 850,600
      C 860,622 885,635 912,630
      L 932,605
      C 918,590 910,570 918,548
      Z"
      fill="#0B1A30"
    />
  </g>

  <!-- ==================== TYPOGRAPHY SECTION ==================== -->
  <!-- "Auto" (Navy #071739 with embedded wrench in 'o') -->
  <g id="brand-text-auto">
    <!-- Letter A -->
    <path d="M 45,860 L 105,735 L 145,735 L 205,860 L 165,860 L 150,826 L 100,826 L 85,860 Z M 110,800 L 140,800 L 125,765 Z" fill="#071739"/>
    <!-- Letter u -->
    <path d="M 215,772 L 247,772 L 247,828 C 247,838 253,842 262,842 C 271,842 277,838 277,828 L 277,772 L 309,772 L 309,832 C 309,853 293,863 262,863 C 231,863 215,853 215,832 Z" fill="#071739"/>
    <!-- Letter t -->
    <path d="M 330,748 L 358,748 L 358,772 L 382,772 L 382,794 L 358,794 L 358,838 C 358,842 360,845 365,845 L 382,845 L 382,860 C 374,863 360,863 348,860 C 336,856 330,846 330,832 L 330,794 L 318,794 L 318,772 L 330,772 Z" fill="#071739"/>
    <!-- Letter o with Wrench icon in center -->
    <path d="M 390,816 C 390,788 412,768 444,768 C 476,768 498,788 498,816 C 498,844 476,864 444,864 C 412,864 390,844 390,816 Z" fill="#071739"/>
    <!-- Wrench in 'o' -->
    <path d="M 436,804 L 452,792 L 460,800 L 448,812 L 458,826 L 450,834 L 436,820 L 428,828 L 420,820 L 428,812 Z" fill="#FFFFFF"/>
    <circle cx="452" cy="796" r="3" fill="#071739"/>
  </g>

  <!-- "parts" (Royal Blue #0066FF) -->
  <g id="brand-text-parts" fill="#0066FF">
    <!-- Letter p -->
    <path d="M 510,772 L 540,772 L 540,785 C 548,774 560,768 574,768 C 596,768 614,788 614,816 C 614,844 596,864 574,864 C 560,864 548,858 540,847 L 540,885 L 510,885 Z M 540,816 C 540,830 550,842 562,842 C 574,842 584,830 584,816 C 584,802 574,790 562,790 C 550,790 540,802 540,816 Z"/>
    <!-- Letter a -->
    <path d="M 624,816 C 624,790 642,768 668,768 C 682,768 694,775 700,786 L 700,772 L 728,772 L 728,860 L 700,860 L 700,846 C 694,857 682,864 668,864 C 642,864 624,842 624,816 Z M 654,816 C 654,830 664,842 676,842 C 688,842 698,830 698,816 C 698,802 688,790 676,790 C 664,790 654,802 654,816 Z"/>
    <!-- Letter r -->
    <path d="M 738,772 L 766,772 L 766,788 C 772,776 784,768 798,768 L 804,768 L 804,796 C 798,795 790,795 784,797 C 772,801 766,812 766,828 L 766,860 L 738,860 Z"/>
    <!-- Letter t -->
    <path d="M 814,748 L 842,748 L 842,772 L 866,772 L 866,794 L 842,794 L 842,838 C 842,842 844,845 849,845 L 866,845 L 866,860 C 858,863 844,863 832,860 C 820,856 814,846 814,832 L 814,794 L 802,794 L 802,772 L 814,772 Z"/>
    <!-- Letter s -->
    <path d="M 876,838 C 882,842 892,846 904,846 C 916,846 922,840 922,834 C 922,826 914,822 900,816 C 880,808 872,798 872,784 C 872,772 884,768 902,768 C 914,768 926,772 932,776 L 924,796 C 918,792 910,790 902,790 C 894,790 888,794 888,798 C 888,804 896,808 910,814 C 930,822 938,832 938,846 C 938,862 924,868 904,868 C 890,868 878,862 870,856 Z"/>
  </g>

  <!-- "India" (Navy #071739) -->
  <g id="brand-text-india" fill="#071739">
    <!-- Letter I -->
    <path d="M 952,735 L 980,735 L 980,860 L 952,860 Z"/>
    <!-- Dot on i -->
    <circle cx="966" cy="718" r="14" fill="#0066FF"/>
  </g>

  <!-- ==================== TAGLINE SECTION ==================== -->
  <!-- Blue Left Rule -->
  <rect x="70" y="915" width="90" height="8" rx="4" fill="#0066FF"/>

  <!-- Tagline Text: BUY • SELL • FIND • AUTO PARTS -->
  <g id="tagline-text" fill="#0A1931">
    <text x="512" y="924" font-family="'Plus Jakarta Sans', 'Poppins', 'Segoe UI', Arial, sans-serif" font-size="28" font-weight="900" letter-spacing="3" text-anchor="middle">
      <tspan fill="#0066FF">BUY</tspan>
      <tspan fill="#0066FF" font-size="34"> • </tspan>
      <tspan fill="#0A1931">SELL</tspan>
      <tspan fill="#0066FF" font-size="34"> • </tspan>
      <tspan fill="#0066FF">FIND</tspan>
      <tspan fill="#0066FF" font-size="34"> • </tspan>
      <tspan fill="#0A1931">AUTO PARTS</tspan>
    </text>
  </g>

  <!-- Blue Right Rule -->
  <rect x="864" y="915" width="90" height="8" rx="4" fill="#0066FF"/>
</svg>
`;

// 2. Icon-Only SVG Badge (Car + Gear + Wrench centered without text for App Icons & Avatars)
export const ICON_ONLY_SVG = `
<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="iconGearGrad" x1="512" y1="40" x2="512" y2="980" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#0088FF"/>
      <stop offset="40%" stop-color="#0060E6"/>
      <stop offset="100%" stop-color="#0035A8"/>
    </linearGradient>
    <linearGradient id="iconGearBevel" x1="60" y1="40" x2="964" y2="980" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#38B6FF"/>
      <stop offset="50%" stop-color="#0066FF"/>
      <stop offset="100%" stop-color="#002277"/>
    </linearGradient>
    <linearGradient id="iconWindshield" x1="512" y1="280" x2="512" y2="470" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#004BBB"/>
      <stop offset="100%" stop-color="#002166"/>
    </linearGradient>
    <linearGradient id="iconLight" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#00F0FF"/>
      <stop offset="100%" stop-color="#0088FF"/>
    </linearGradient>
    <linearGradient id="iconChrome" x1="160" y1="580" x2="920" y2="780" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#E2E8F0"/>
      <stop offset="50%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#CBD5E1"/>
    </linearGradient>
    <linearGradient id="iconSwoosh" x1="100" y1="580" x2="800" y2="820" gradientUnits="userSpaceOnUse">
      <stop offset="0%" stop-color="#00E5FF"/>
      <stop offset="50%" stop-color="#0080FF"/>
      <stop offset="100%" stop-color="#0052CC"/>
    </linearGradient>
    <filter id="iconShadow" x="-10%" y="-10%" width="120%" height="120%">
      <feDropShadow dx="0" dy="16" stdDeviation="20" flood-color="#001844" flood-opacity="0.4"/>
    </filter>
  </defs>

  <rect width="1024" height="1024" rx="224" fill="#0B1220"/>

  <g transform="translate(0, -10)" filter="url(#iconShadow)">
    <!-- 8-Teeth Gear -->
    <path d="
      M 426,80 L 598,80 L 612,178 Q 674,196 730,228 L 824,170 L 924,270 L 866,364 Q 898,420 916,482 L 1014,496 L 1014,668 L 916,682 Q 898,744 866,800 L 924,894 L 824,994 L 730,936 Q 674,968 612,986 L 598,1084 L 426,1084 L 412,986 Q 350,968 294,936 L 200,994 L 100,894 L 158,800 Q 126,744 108,682 L 10,668 L 10,496 L 108,482 Q 126,420 158,364 L 100,270 L 200,170 L 294,228 Q 350,196 412,178 Z"
      transform="matrix(0.92 0 0 0.92 41 20)"
      fill="url(#iconGearGrad)"
      stroke="url(#iconGearBevel)"
      stroke-width="12"
      stroke-linejoin="round"
    />

    <!-- Inner Groove -->
    <circle cx="512" cy="530" r="375" fill="#04122C" stroke="#0055D4" stroke-width="10"/>
    <circle cx="512" cy="530" r="355" fill="#0A224A"/>

    <!-- Car Shield White Base -->
    <path d="M 200,510 C 200,330 310,220 512,220 C 714,220 824,330 824,510 C 824,690 700,760 512,760 C 324,760 200,690 200,510 Z" fill="#F8FAFC"/>

    <!-- Car Cabin Roof & Pillars -->
    <path d="M 310,430 L 360,315 C 376,290 416,280 512,280 C 608,280 648,290 664,315 L 714,430 Z" fill="#0B1A30"/>
    
    <!-- Windshield -->
    <path d="M 326,425 L 372,320 C 388,302 420,295 512,295 C 604,295 636,302 652,320 L 698,425 Z" fill="url(#iconWindshield)"/>
    <path d="M 390,315 L 355,420 L 415,420 L 450,315 Z" fill="#38B6FF" opacity="0.35"/>

    <!-- Mirrors -->
    <path d="M 308,406 C 278,406 264,422 278,438 C 294,450 316,446 322,432 Z" fill="#F1F5F9" stroke="#0B1A30" stroke-width="4"/>
    <path d="M 716,406 C 746,406 760,422 746,438 C 730,450 708,446 702,432 Z" fill="#F1F5F9" stroke="#0B1A30" stroke-width="4"/>

    <!-- Car Body Hood & Fenders -->
    <path d="
      M 315,432 
      C 245,444 180,488 168,546 
      C 160,596 185,640 235,662 
      L 290,675 
      C 356,686 668,686 734,675 
      L 789,662 
      C 839,640 864,596 856,546 
      C 844,488 779,444 709,432 
      C 644,424 380,424 315,432 Z" 
      fill="#FFFFFF" 
      stroke="#0B1A30" 
      stroke-width="9"
    />

    <!-- Front Grille -->
    <path d="M 342,525 C 342,520 355,516 512,516 C 669,516 682,520 682,525 L 664,600 C 660,612 642,616 512,616 C 382,616 364,612 360,600 Z" fill="#081426" stroke="#0F2442" stroke-width="7"/>
    <path d="M 360,538 Q 512,535 664,538" stroke="#38B6FF" stroke-width="4.5" opacity="0.9"/>
    <path d="M 364,558 Q 512,555 660,558" stroke="#FFFFFF" stroke-width="4" opacity="0.85"/>
    <path d="M 370,578 Q 512,575 654,578" stroke="#38B6FF" stroke-width="4.5" opacity="0.9"/>
    <path d="M 382,598 Q 512,596 642,598" stroke="#CBD5E1" stroke-width="3.5" opacity="0.7"/>

    <!-- Left Projector Headlight -->
    <path d="M 200,510 C 240,510 310,518 324,556 C 310,567 240,571 196,545 C 187,530 189,516 200,510 Z" fill="#09182E" stroke="#0044BB" stroke-width="4.5"/>
    <path d="M 210,521 C 245,523 300,532 311,552 C 278,561 234,559 210,541 Z" fill="url(#iconLight)"/>
    <ellipse cx="258" cy="537" rx="16" ry="7" fill="#FFFFFF"/>

    <!-- Right Projector Headlight -->
    <path d="M 824,510 C 784,510 714,518 700,556 C 714,567 784,571 828,545 C 837,530 835,516 824,510 Z" fill="#09182E" stroke="#0044BB" stroke-width="4.5"/>
    <path d="M 814,521 C 779,523 724,532 713,552 C 746,561 790,559 814,541 Z" fill="url(#iconLight)"/>
    <ellipse cx="766" cy="537" rx="16" ry="7" fill="#FFFFFF"/>

    <!-- Sweeping Wrench & Swoosh -->
    <path d="
      M 115,575
      C 105,640 150,740 270,785
      C 400,835 655,810 820,740
      C 755,768 570,812 390,790
      C 250,770 145,705 115,575 Z"
      fill="url(#iconSwoosh)"
    />

    <path d="
      M 135,590
      C 130,662 200,745 345,768
      C 510,792 710,738 810,672
      L 805,630
      C 820,618 855,585 900,585
      C 945,585 978,618 984,658
      C 990,695 968,735 928,758
      C 900,774 845,785 810,782
      C 690,830 480,835 315,800
      C 195,775 120,690 135,590 Z"
      fill="url(#iconChrome)"
      stroke="#0B1A30"
      stroke-width="8"
      stroke-linejoin="round"
    />

    <!-- Wrench Jaws Cutout -->
    <path d="
      M 905,588
      C 882,608 877,635 888,664
      C 900,688 928,702 958,698
      L 980,670
      C 965,652 956,630 965,605
      Z"
      fill="#0B1A30"
    />
  </g>
</svg>
`;

async function generateAllBrandingAssets() {
  console.log('🚀 Generating 100% authentic Auto Parts India branding assets...');

  const masterSvgBuffer = Buffer.from(MASTER_LOGO_SVG);
  const iconSvgBuffer = Buffer.from(ICON_ONLY_SVG);

  // 1. Write SVGs to public/
  const publicDir = path.join(process.cwd(), 'public');
  const publicAssetsDir = path.join(publicDir, 'assets');
  if (!fs.existsSync(publicAssetsDir)) fs.mkdirSync(publicAssetsDir, { recursive: true });

  fs.writeFileSync(path.join(publicDir, 'favicon.svg'), iconSvgBuffer);
  fs.writeFileSync(path.join(publicDir, 'app-icon.svg'), masterSvgBuffer);
  fs.writeFileSync(path.join(publicAssetsDir, 'logo.svg'), masterSvgBuffer);
  fs.writeFileSync(path.join(publicAssetsDir, 'logo_icon.svg'), iconSvgBuffer);

  // 2. Generate Web PNGs in public/
  await sharp(masterSvgBuffer).resize(1024, 1024).png().toFile(path.join(publicAssetsDir, 'logo.png'));
  await sharp(iconSvgBuffer).resize(1024, 1024).png().toFile(path.join(publicAssetsDir, 'logo_icon.png'));
  await sharp(iconSvgBuffer).resize(512, 512).png().toFile(path.join(publicDir, 'icon-512.png'));
  await sharp(iconSvgBuffer).resize(192, 192).png().toFile(path.join(publicDir, 'icon-192.png'));
  await sharp(iconSvgBuffer).resize(512, 512).png().toFile(path.join(publicDir, 'app-icon.png'));
  await sharp(iconSvgBuffer).resize(512, 512).png().toFile(path.join(publicDir, 'adaptive-icon.png'));
  await sharp(iconSvgBuffer).resize(64, 64).png().toFile(path.join(publicDir, 'favicon.png'));

  // 3. Generate React Native JS Asset PNGs
  const rnAssetsDir = path.join(process.cwd(), 'react-native-app/src/assets');
  if (!fs.existsSync(rnAssetsDir)) fs.mkdirSync(rnAssetsDir, { recursive: true });
  await sharp(masterSvgBuffer).resize(1024, 1024).png().toFile(path.join(rnAssetsDir, 'logo.png'));
  await sharp(iconSvgBuffer).resize(512, 512).png().toFile(path.join(rnAssetsDir, 'logo_icon.png'));

  // 4. Generate Android Native Mipmaps & Drawables for both react-native-app/android and root /android
  const androidResDirs = [
    path.join(process.cwd(), 'react-native-app/android/app/src/main/res'),
    path.join(process.cwd(), 'android/app/src/main/res')
  ];

  const mipmaps = [
    { dir: 'mipmap-mdpi', size: 48, fgSize: 108 },
    { dir: 'mipmap-hdpi', size: 72, fgSize: 162 },
    { dir: 'mipmap-xhdpi', size: 96, fgSize: 216 },
    { dir: 'mipmap-xxhdpi', size: 144, fgSize: 324 },
    { dir: 'mipmap-xxxhdpi', size: 192, fgSize: 432 },
  ];

  const drawables = [
    { dir: 'drawable', size: 512 },
    { dir: 'drawable-mdpi', size: 160 },
    { dir: 'drawable-hdpi', size: 240 },
    { dir: 'drawable-xhdpi', size: 320 },
    { dir: 'drawable-xxhdpi', size: 480 },
    { dir: 'drawable-xxxhdpi', size: 640 },
  ];

  for (const resDir of androidResDirs) {
    if (!fs.existsSync(resDir)) continue;

    // Write Mipmaps (App Launcher Icons)
    for (const m of mipmaps) {
      const dirPath = path.join(resDir, m.dir);
      if (!fs.existsSync(dirPath)) fs.mkdirSync(dirPath, { recursive: true });

      await sharp(iconSvgBuffer).resize(m.size, m.size).png().toFile(path.join(dirPath, 'ic_launcher.png'));
      await sharp(iconSvgBuffer).resize(m.size, m.size).png().toFile(path.join(dirPath, 'ic_launcher_round.png'));
      await sharp(iconSvgBuffer).resize(m.fgSize, m.fgSize).png().toFile(path.join(dirPath, 'ic_launcher_foreground.png'));
    }

    // Write Drawables (Splash Screen and Master Logos)
    for (const d of drawables) {
      const dirPath = path.join(resDir, d.dir);
      if (!fs.existsSync(dirPath)) fs.mkdirSync(dirPath, { recursive: true });

      await sharp(masterSvgBuffer).resize(d.size, d.size).png().toFile(path.join(dirPath, 'splash_logo.png'));
      await sharp(masterSvgBuffer).resize(d.size, d.size).png().toFile(path.join(dirPath, 'master_logo.png'));
      await sharp(iconSvgBuffer).resize(d.size, d.size).png().toFile(path.join(dirPath, 'icon_logo.png'));
    }
  }

  console.log('✅ ALL Auto Parts India Branding assets generated with 100% precision!');
}

generateAllBrandingAssets().catch(console.error);
