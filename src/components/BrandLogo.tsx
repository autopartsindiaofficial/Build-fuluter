import React from 'react';

export interface BrandLogoProps {
  name?: string;
  brand?: string;
  logoUrl?: string;
  imageUrl?: string;
  size?: number | 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl' | string;
  className?: string;
  active?: boolean;
  variant?: 'icon' | 'full' | 'horizontal' | string;
  theme?: 'dark' | 'light' | string;
  showTagline?: boolean;
}

const SIZE_MAP: Record<string, number> = {
  xs: 20,
  sm: 32,
  md: 44,
  lg: 64,
  xl: 96,
  '2xl': 128,
};

function CarBrandImage({ brandKey, logoUrl, size }: { brandKey: string; logoUrl?: string; size: number }) {
  const [hasError, setHasError] = React.useState(false);

  if (logoUrl && !hasError) {
    return (
      <img
        src={logoUrl}
        alt={brandKey}
        onError={() => setHasError(true)}
        style={{
          width: size,
          height: size,
          objectFit: 'contain',
        }}
        className="select-none pointer-events-none p-0.5 max-w-full max-h-full"
        draggable={false}
      />
    );
  }

  const code = (brandKey || "CAR").substring(0, 3).toUpperCase();
  return (
    <div 
      className="flex items-center justify-center rounded-lg bg-blue-50 border border-blue-200 text-blue-600 font-extrabold text-[11px] select-none shadow-2xs"
      style={{ width: size, height: size }}
    >
      {code}
    </div>
  );
}


export function AutoPartsRoundLogo({
  size = 40,
  className = '',
  border = true,
  bgColor = '#0075FF',
}: {
  size?: number;
  className?: string;
  border?: boolean;
  bgColor?: string;
}) {
  const [imgError, setImgError] = React.useState(false);

  return (
    <div
      className={`rounded-2xl flex items-center justify-center shrink-0 overflow-hidden shadow-md select-none bg-white p-1 ${
        border ? 'ring-2 ring-white/60' : ''
      } ${className}`}
      style={{
        width: size,
        height: size,
      }}
    >
      {!imgError ? (
        <img
          src="/brand_logo.png"
          alt="Auto Parts Brand Logo"
          className="w-full h-full object-contain pointer-events-none"
          onError={() => setImgError(true)}
        />
      ) : (
        <svg width={size * 0.88} height={size * 0.88} viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
          <g transform="translate(0, -10)">
            <circle cx="100" cy="75" r="32" stroke="#0075FF" strokeWidth="8" fill="none" />
            <circle cx="100" cy="75" r="12" stroke="#0075FF" strokeWidth="4" fill="none" />
            <path
              d="M60,92 C63,78 68,70 100,70 C132,70 137,78 140,92 C150,95 156,100 156,110 C156,121 148,123 138,123 L62,123 C52,123 44,121 44,110 C44,100 50,95 60,92 Z"
              fill="#0075FF"
            />
          </g>
        </svg>
      )}
    </div>
  );
}

export function BrandLogo({ 
  name = '', 
  brand = '', 
  logoUrl,
  imageUrl,
  size = 32, 
  className = '', 
  variant = 'full'
}: BrandLogoProps) {

  const numericSize = typeof size === 'number' 
    ? size 
    : (SIZE_MAP[size] || 32);
  const safeSize = Number.isFinite(numericSize) && numericSize > 0 ? numericSize : 32;
  const brandKey = String(brand || name || '').toLowerCase().trim();

  // If a car brand is specified
  if (brandKey && brandKey !== 'all' && brandKey !== 'all brands') {
    return (
      <div className={`flex items-center justify-center shrink-0 ${className}`} style={{ width: safeSize, height: safeSize }}>
        <CarBrandImage brandKey={brandKey} logoUrl={logoUrl || imageUrl} size={safeSize} />
      </div>
    );
  }


  // Round Brand Emblem
  if (variant === 'round') {
    return <AutoPartsRoundLogo size={safeSize} className={className} />;
  }

  // APP BRANDING LOGO: Use Official Auto Parts India Logo
  if (variant === 'icon') {
    return <AutoPartsRoundLogo size={safeSize} className={className} border={false} />;
  }

  // Full / Horizontal / Default App Logo
  return (
    <div className={`flex items-center gap-2 select-none ${className}`}>
      <AutoPartsRoundLogo size={Math.min(safeSize, 36)} border={true} />
      <div className="flex flex-col justify-center leading-none">
        <span className="font-black text-xs sm:text-sm tracking-tight text-white font-sans">AUTO PARTS</span>
        <span className="font-extrabold text-[9px] sm:text-[10px] tracking-widest text-sky-400 font-sans">INDIA</span>
      </div>
    </div>
  );
}

export function CarBrandBadge(props: BrandLogoProps) {
  return <BrandLogo {...props} />;
}

export function GearSpeedLogoIcon({ size = 48 }: { size?: number }) {
  return (
    <img
      src="/assets/logo_icon.svg"
      alt="Auto Parts Logo"
      style={{ width: size, height: size, objectFit: 'contain' }}
      className="drop-shadow-lg select-none"
    />
  );
}

export default BrandLogo;

