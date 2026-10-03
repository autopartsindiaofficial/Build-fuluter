import React, { useEffect, useState, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";

interface SplashScreenProps {
  onFinish?: () => void;
  minDurationMs?: number;
  isReady?: boolean;
}

export default function SplashScreen({
  onFinish,
  minDurationMs = 1500,
  isReady = true
}: SplashScreenProps) {
  const [visible, setVisible] = useState(true);
  const [minTimeElapsed, setMinTimeElapsed] = useState(false);
  const hasFinishedRef = useRef(false);

  useEffect(() => {
    // Prevent scrolling while splash screen is active
    const originalOverflow = document.body.style.overflow;
    const originalTouchAction = document.body.style.touchAction;
    document.body.style.overflow = "hidden";
    document.body.style.touchAction = "none";

    const minTimer = setTimeout(() => {
      setMinTimeElapsed(true);
    }, minDurationMs);

    // Hard fallback safety: never keep splash open longer than 3.0s under any condition
    const maxTimer = setTimeout(() => {
      setMinTimeElapsed(true);
      if (!hasFinishedRef.current) {
        setVisible(false);
      }
    }, 3000);

    return () => {
      clearTimeout(minTimer);
      clearTimeout(maxTimer);
      document.body.style.overflow = originalOverflow;
      document.body.style.touchAction = originalTouchAction;
    };
  }, [minDurationMs]);

  useEffect(() => {
    if (minTimeElapsed && isReady && visible && !hasFinishedRef.current) {
      setVisible(false);
    }
  }, [minTimeElapsed, isReady, visible]);

  return (
    <AnimatePresence 
      onExitComplete={() => {
        if (!hasFinishedRef.current) {
          hasFinishedRef.current = true;
          if (onFinish) {
            onFinish();
          }
        }
      }}
    >
      {visible && (
        <motion.div
          key="native-mobile-splash-screen"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ 
            opacity: 0,
            transition: { duration: 0.35, ease: "easeInOut" } 
          }}
          className="fixed inset-0 z-[99999] w-screen h-screen bg-[#25242E] flex flex-col items-center justify-center select-none overflow-hidden touch-none"
          style={{ height: "100dvh", width: "100vw", backgroundColor: "#25242E" }}
          id="app-native-splash-screen"
        >
          {/* Main Content Area: Exact Reference Image Display */}
          <motion.div 
            initial={{ scale: 0.98, opacity: 0.95 }}
            animate={{ scale: 1, opacity: 1 }}
            transition={{ duration: 0.45, ease: "easeOut" }}
            className="relative w-full h-full max-w-md max-h-screen flex items-center justify-center p-0"
          >
            <picture className="w-full h-full flex items-center justify-center">
              <source srcSet="/assets/splash_reference.webp" type="image/webp" />
              <img 
                src="/assets/splash_reference.png" 
                alt="Auto Parts India" 
                className="w-full h-full object-contain pointer-events-none select-none drop-shadow-2xl"
                draggable={false}
              />
            </picture>

            {/* Subtle bottom indicator matching reference orange accent */}
            <div className="absolute bottom-6 left-0 right-0 flex items-center justify-center pointer-events-none">
              <div className="w-5 h-5 rounded-full border-2 border-[#FF7300]/30 border-t-[#FF7300] animate-spin" />
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
