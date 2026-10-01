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
  return (
    <div
      className={`rounded-2xl flex items-center justify-center shrink-0 overflow-hidden shadow-md select-none ${
        border ? 'ring-2 ring-white/60' : ''
      } ${className}`}
      style={{
        width: size,
        height: size,
        backgroundColor: bgColor,
      }}
    >
      <svg width={size * 0.65} height={size * 0.65} viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.5 2.8C2.1 10.7 2 11.2 2 11.7V16c0 .6.4 1 1 1h2" />
        <circle cx="7" cy="17" r="2" />
        <path d="M9 17h6" />
        <circle cx="17" cy="17" r="2" />
      </svg>
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

