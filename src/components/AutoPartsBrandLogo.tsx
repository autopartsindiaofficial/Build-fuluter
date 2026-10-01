import React from 'react';

interface AutoPartsBrandLogoProps {
  className?: string;
  size?: number | string;
  variant?: 'light' | 'dark' | 'splash' | 'white';
  showText?: boolean;
}

/**
 * Official AutoParts INDIA Vector Brand Logo Component
 * - "Auto" in White (on dark/splash) or Deep Slate (on light)
 * - "Parts" in Signature Automotive Navy Blue
 * - "INDIA" in Vibrant Orange with Dynamic Speed Arrows
 */
export default function AutoPartsBrandLogo({
  className = "",
  size = 280,
}: AutoPartsBrandLogoProps) {
  const width = typeof size === 'number' ? size : 280;

  return (
    <div className={`flex flex-col items-center justify-center select-none ${className}`} style={{ width }}>
      <div className="w-16 h-16 rounded-2xl bg-blue-600 flex items-center justify-center shadow-lg mb-3">
        <svg className="w-9 h-9 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.5 2.8C2.1 10.7 2 11.2 2 11.7V16c0 .6.4 1 1 1h2" />
          <circle cx="7" cy="17" r="2" />
          <path d="M9 17h6" />
          <circle cx="17" cy="17" r="2" />
        </svg>
      </div>
      <span className="text-2xl font-black tracking-tight text-slate-900">Auto Parts India</span>
      <span className="text-[11px] font-extrabold tracking-widest text-blue-600 uppercase mt-1">Genuine Spares Network</span>
    </div>
  );
}

