import React, { useState, useEffect, useRef, useCallback } from "react";
import { X, ChevronLeft, ChevronRight, Share2, Download, Info } from "lucide-react";
import { SparePart } from "../types";

interface ImageGalleryModalProps {
  isOpen: boolean;
  onClose: () => void;
  part: SparePart | null;
  initialIndex?: number;
}

export default function ImageGalleryModal({ isOpen, onClose, part, initialIndex = 0 }: ImageGalleryModalProps) {
  // Extract all valid image URLs
  const images: string[] = [];
  if (part) {
    if (part.imageUrls && part.imageUrls.length > 0) {
      part.imageUrls.forEach(url => {
        if (url && !images.includes(url)) {
          images.push(url);
        }
      });
    } else if (part.imageUrl) {
      images.push(part.imageUrl);
    }
  }

  const [currentIndex, setCurrentIndex] = useState(initialIndex);
  const [scale, setScale] = useState(1);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [showDetails, setShowDetails] = useState(true);

  // Mutable refs for zero-lag touch/pinch/pan execution
  const scaleRef = useRef(scale);
  scaleRef.current = scale;

  const positionRef = useRef(position);
  positionRef.current = position;

  const currentIndexRef = useRef(currentIndex);
  currentIndexRef.current = currentIndex;

  const containerRef = useRef<HTMLDivElement>(null);
  const imgRef = useRef<HTMLImageElement>(null);

  // Apply transform directly to DOM element for 60fps buttery-smooth zero-lag experience
  const updateTransformDirectly = (x: number, y: number, currentScale: number, animate = false) => {
    if (imgRef.current) {
      imgRef.current.style.transform = `translate3d(${x}px, ${y}px, 0px) scale(${currentScale})`;
      imgRef.current.style.transition = animate ? "transform 250ms cubic-bezier(0.2, 0, 0.2, 1)" : "none";
    }
  };

  // Touch & gesture tracking refs
  const lastTapRef = useRef<{ time: number; x: number; y: number } | null>(null);
  const touchStateRef = useRef<{
    mode: "idle" | "drag" | "pinch";
    startX: number;
    startY: number;
    initialPos: { x: number; y: number };
    initialScale: number;
    initialDist: number;
    initialCenter: { x: number; y: number };
    touchStartTime: number;
  }>({
    mode: "idle",
    startX: 0,
    startY: 0,
    initialPos: { x: 0, y: 0 },
    initialScale: 1,
    initialDist: 0,
    initialCenter: { x: 0, y: 0 },
    touchStartTime: 0
  });

  // Calculate pan clamping
  const clampPosition = useCallback((pos: { x: number; y: number }, targetScale: number) => {
    if (targetScale <= 1 || !containerRef.current) {
      return { x: 0, y: 0 };
    }
    const container = containerRef.current.getBoundingClientRect();
    const maxPanX = Math.max(0, (container.width * (targetScale - 1)) / 2);
    const maxPanY = Math.max(0, (container.height * (targetScale - 1)) / 2);

    return {
      x: Math.max(-maxPanX, Math.min(maxPanX, pos.x)),
      y: Math.max(-maxPanY, Math.min(maxPanY, pos.y))
    };
  }, []);

  // Smooth reset to 1x fit-screen view
  const resetZoom = useCallback((animate = true) => {
    setScale(1);
    setPosition({ x: 0, y: 0 });
    scaleRef.current = 1;
    positionRef.current = { x: 0, y: 0 };
    updateTransformDirectly(0, 0, 1, animate);
  }, []);

  // Double tap / double click action: Toggle between 1x and 2.5x at tapped coordinates
  const handleDoubleTap = useCallback((clientX: number, clientY: number) => {
    if (scaleRef.current > 1.15) {
      resetZoom(true);
    } else if (containerRef.current) {
      const rect = containerRef.current.getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;

      const offsetX = clientX - cx;
      const offsetY = clientY - cy;
      const targetScale = 2.5;

      const targetPos = clampPosition({
        x: -offsetX * targetScale,
        y: -offsetY * targetScale
      }, targetScale);

      setScale(targetScale);
      setPosition(targetPos);
      scaleRef.current = targetScale;
      positionRef.current = targetPos;
      updateTransformDirectly(targetPos.x, targetPos.y, targetScale, true);
    }
  }, [clampPosition, resetZoom]);

  // Lock body scroll and prevent page bounce on mount/open
  useEffect(() => {
    if (isOpen) {
      const prevOverflow = document.body.style.overflow;
      document.body.style.overflow = "hidden";
      return () => {
        document.body.style.overflow = prevOverflow;
      };
    }
  }, [isOpen]);

  // Sync index and reset transforms on open or index change
  useEffect(() => {
    if (isOpen) {
      const validIndex = initialIndex >= 0 && initialIndex < images.length ? initialIndex : 0;
      setCurrentIndex(validIndex);
      resetZoom(false);
    }
  }, [isOpen, initialIndex, images.length, resetZoom]);

  // Switch index cleanly
  const handleSelectIndex = (idx: number) => {
    if (idx >= 0 && idx < images.length && idx !== currentIndex) {
      resetZoom(false);
      setCurrentIndex(idx);
    }
  };

  // Keyboard navigation & Esc to close
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        onClose();
      } else if (e.key === "ArrowLeft" && images.length > 1 && scaleRef.current <= 1.1) {
        handleSelectIndex(currentIndex > 0 ? currentIndex - 1 : images.length - 1);
      } else if (e.key === "ArrowRight" && images.length > 1 && scaleRef.current <= 1.1) {
        handleSelectIndex(currentIndex < images.length - 1 ? currentIndex + 1 : 0);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, currentIndex, images.length, onClose]);

  // Native non-passive Touch & Gesture Handling (Zero Lag direct DOM transforms)
  useEffect(() => {
    const container = containerRef.current;
    if (!isOpen || !container) return;

    const onTouchStart = (e: TouchEvent) => {
      const now = Date.now();

      if (e.touches.length === 1) {
        const touch = e.touches[0];

        // Double-tap detection
        if (
          lastTapRef.current &&
          now - lastTapRef.current.time < 320 &&
          Math.hypot(touch.clientX - lastTapRef.current.x, touch.clientY - lastTapRef.current.y) < 35
        ) {
          e.preventDefault();
          lastTapRef.current = null;
          touchStateRef.current.mode = "idle";
          handleDoubleTap(touch.clientX, touch.clientY);
          return;
        }

        lastTapRef.current = {
          time: now,
          x: touch.clientX,
          y: touch.clientY
        };

        touchStateRef.current = {
          mode: "drag",
          startX: touch.clientX,
          startY: touch.clientY,
          initialPos: { ...positionRef.current },
          initialScale: scaleRef.current,
          initialDist: 0,
          initialCenter: { x: 0, y: 0 },
          touchStartTime: now
        };
      } else if (e.touches.length === 2) {
        e.preventDefault();
        const t1 = e.touches[0];
        const t2 = e.touches[1];
        const dist = Math.hypot(t1.clientX - t2.clientX, t1.clientY - t2.clientY);
        const center = {
          x: (t1.clientX + t2.clientX) / 2,
          y: (t1.clientY + t2.clientY) / 2
        };

        touchStateRef.current = {
          mode: "pinch",
          startX: 0,
          startY: 0,
          initialPos: { ...positionRef.current },
          initialScale: scaleRef.current,
          initialDist: dist,
          initialCenter: center,
          touchStartTime: now
        };
      }
    };

    const onTouchMove = (e: TouchEvent) => {
      if (touchStateRef.current.mode === "idle") return;

      if (e.touches.length === 2 && touchStateRef.current.mode === "pinch" && touchStateRef.current.initialDist > 0) {
        e.preventDefault();
        const t1 = e.touches[0];
        const t2 = e.touches[1];
        const currentDist = Math.hypot(t1.clientX - t2.clientX, t1.clientY - t2.clientY);
        const pinchRatio = currentDist / touchStateRef.current.initialDist;
        const targetScale = Math.min(Math.max(touchStateRef.current.initialScale * pinchRatio, 0.8), 5.0);

        const currentCenter = {
          x: (t1.clientX + t2.clientX) / 2,
          y: (t1.clientY + t2.clientY) / 2
        };
        const centerDeltaX = currentCenter.x - touchStateRef.current.initialCenter.x;
        const centerDeltaY = currentCenter.y - touchStateRef.current.initialCenter.y;

        const targetPos = clampPosition({
          x: touchStateRef.current.initialPos.x + centerDeltaX,
          y: touchStateRef.current.initialPos.y + centerDeltaY
        }, targetScale);

        scaleRef.current = targetScale;
        positionRef.current = targetPos;
        updateTransformDirectly(targetPos.x, targetPos.y, targetScale, false);
      } else if (e.touches.length === 1 && touchStateRef.current.mode === "drag") {
        const touch = e.touches[0];
        const deltaX = touch.clientX - touchStateRef.current.startX;
        const deltaY = touch.clientY - touchStateRef.current.startY;

        if (scaleRef.current > 1.05) {
          e.preventDefault();
          const targetPos = clampPosition({
            x: touchStateRef.current.initialPos.x + deltaX,
            y: touchStateRef.current.initialPos.y + deltaY
          }, scaleRef.current);

          positionRef.current = targetPos;
          updateTransformDirectly(targetPos.x, targetPos.y, scaleRef.current, false);
        }
      }
    };

    const onTouchEnd = (e: TouchEvent) => {
      const state = touchStateRef.current;
      touchStateRef.current.mode = "idle";

      // Sync state back from refs on touch end
      setScale(scaleRef.current);
      setPosition({ ...positionRef.current });

      if (scaleRef.current < 1) {
        resetZoom(true);
      } else if (scaleRef.current <= 1.05 && e.changedTouches.length === 1 && state.mode === "drag") {
        const touch = e.changedTouches[0];
        const deltaX = touch.clientX - state.startX;
        const deltaY = touch.clientY - state.startY;
        const duration = Date.now() - state.touchStartTime;

        if (Math.abs(deltaX) > 55 && Math.abs(deltaY) < 90 && duration < 350 && images.length > 1) {
          if (deltaX > 0) {
            handleSelectIndex(currentIndexRef.current > 0 ? currentIndexRef.current - 1 : images.length - 1);
          } else {
            handleSelectIndex(currentIndexRef.current < images.length - 1 ? currentIndexRef.current + 1 : 0);
          }
        }
      }
    };

    // Wheel / Trackpad Zoom
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      const zoomFactor = e.deltaY < 0 ? 1.15 : 0.88;
      const rect = container.getBoundingClientRect();
      const cursorX = e.clientX - (rect.left + rect.width / 2);
      const cursorY = e.clientY - (rect.top + rect.height / 2);

      const prevScale = scaleRef.current;
      const nextScale = Math.min(Math.max(prevScale * zoomFactor, 1), 5.0);

      if (nextScale <= 1) {
        scaleRef.current = 1;
        positionRef.current = { x: 0, y: 0 };
        setScale(1);
        setPosition({ x: 0, y: 0 });
        updateTransformDirectly(0, 0, 1, false);
        return;
      }

      const ratio = nextScale / prevScale;
      const targetPos = clampPosition({
        x: cursorX - (cursorX - positionRef.current.x) * ratio,
        y: cursorY - (cursorY - positionRef.current.y) * ratio
      }, nextScale);

      scaleRef.current = nextScale;
      positionRef.current = targetPos;
      setScale(nextScale);
      setPosition(targetPos);
      updateTransformDirectly(targetPos.x, targetPos.y, nextScale, false);
    };

    container.addEventListener("touchstart", onTouchStart, { passive: false });
    container.addEventListener("touchmove", onTouchMove, { passive: false });
    container.addEventListener("touchend", onTouchEnd, { passive: false });
    container.addEventListener("touchcancel", onTouchEnd, { passive: false });
    container.addEventListener("wheel", onWheel, { passive: false });

    return () => {
      container.removeEventListener("touchstart", onTouchStart);
      container.removeEventListener("touchmove", onTouchMove);
      container.removeEventListener("touchend", onTouchEnd);
      container.removeEventListener("touchcancel", onTouchEnd);
      container.removeEventListener("wheel", onWheel);
    };
  }, [isOpen, images.length, clampPosition, handleDoubleTap, resetZoom]);

  // Desktop Mouse Drag Handling (Zero Lag)
  const mouseDragRef = useRef<{ startX: number; startY: number; initialPos: { x: number; y: number } } | null>(null);

  const handleMouseDown = (e: React.MouseEvent<HTMLDivElement>) => {
    if (e.button !== 0 || scaleRef.current <= 1.05) return;
    mouseDragRef.current = {
      startX: e.clientX,
      startY: e.clientY,
      initialPos: { ...positionRef.current }
    };
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!mouseDragRef.current || scaleRef.current <= 1.05) return;
    const deltaX = e.clientX - mouseDragRef.current.startX;
    const deltaY = e.clientY - mouseDragRef.current.startY;

    const targetPos = clampPosition({
      x: mouseDragRef.current.initialPos.x + deltaX,
      y: mouseDragRef.current.initialPos.y + deltaY
    }, scaleRef.current);

    positionRef.current = targetPos;
    updateTransformDirectly(targetPos.x, targetPos.y, scaleRef.current, false);
  };

  const handleMouseUp = () => {
    if (mouseDragRef.current) {
      setScale(scaleRef.current);
      setPosition({ ...positionRef.current });
      mouseDragRef.current = null;
    }
  };

  if (!isOpen || !part || images.length === 0) return null;

  return (
    <div
      className="fixed inset-0 w-screen h-screen z-[99999] flex flex-col items-center justify-between overflow-hidden select-none"
      style={{
        backgroundColor: "#000000",
        position: "fixed",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        touchAction: "none"
      }}
      id="fullscreen-image-viewer-modal"
    >
      {/* 1. PAKKA REACT NATIVE HEADER BAR */}
      <div className="w-full px-4 py-3 sm:px-6 sm:py-4 flex items-center justify-between bg-gradient-to-b from-black/80 via-black/40 to-transparent z-50 pointer-events-auto">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onClose}
            className="w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 active:scale-95 flex items-center justify-center text-white backdrop-blur-md transition-all cursor-pointer border border-white/10 shadow-lg"
            aria-label="Close viewer"
          >
            <X size={20} className="stroke-[2.5]" />
          </button>
          
          {/* Image Counter Badge (e.g. 1 / 3) */}
          <div className="px-3 py-1.5 rounded-full bg-white/15 backdrop-blur-md border border-white/10 text-white text-xs font-bold tracking-widest shadow-sm">
            {currentIndex + 1} / {images.length}
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => setShowDetails(!showDetails)}
            className={`w-10 h-10 rounded-full flex items-center justify-center backdrop-blur-md transition-all cursor-pointer border shadow-lg ${
              showDetails ? "bg-blue-600 border-blue-400 text-white" : "bg-white/10 border-white/10 text-white hover:bg-white/20"
            }`}
            title="Toggle Details"
          >
            <Info size={18} />
          </button>

          <button
            type="button"
            onClick={() => {
              if (images[currentIndex]) {
                window.open(images[currentIndex], "_blank");
              }
            }}
            className="w-10 h-10 rounded-full bg-white/10 hover:bg-white/20 active:scale-95 flex items-center justify-center text-white backdrop-blur-md transition-all cursor-pointer border border-white/10 shadow-lg"
            title="Open Original"
          >
            <Share2 size={18} />
          </button>
        </div>
      </div>

      {/* 2. MAIN INTERACTIVE IMAGE CANVAS (ZERO LAG DIRECT TRANSFORM) */}
      <div
        ref={containerRef}
        className={`flex-1 w-full h-full flex items-center justify-center overflow-hidden p-0 m-0 relative ${
          scale > 1.05 ? "cursor-grab active:cursor-grabbing" : "cursor-default"
        }`}
        style={{ touchAction: "none" }}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        onDoubleClick={(e) => handleDoubleTap(e.clientX, e.clientY)}
        onClick={() => {
          if (scaleRef.current <= 1.05) {
            setShowDetails(prev => !prev);
          }
        }}
      >
        {/* Left Arrow Button for Desktop / Tablet */}
        {images.length > 1 && currentIndex > 0 && scale <= 1.05 && (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              handleSelectIndex(currentIndex - 1);
            }}
            className="absolute left-4 top-1/2 -translate-y-1/2 z-40 w-11 h-11 rounded-full bg-black/50 hover:bg-black/70 text-white flex items-center justify-center backdrop-blur-md border border-white/15 transition-all cursor-pointer shadow-2xl"
          >
            <ChevronLeft size={24} />
          </button>
        )}

        {/* Right Arrow Button for Desktop / Tablet */}
        {images.length > 1 && currentIndex < images.length - 1 && scale <= 1.05 && (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              handleSelectIndex(currentIndex + 1);
            }}
            className="absolute right-4 top-1/2 -translate-y-1/2 z-40 w-11 h-11 rounded-full bg-black/50 hover:bg-black/70 text-white flex items-center justify-center backdrop-blur-md border border-white/15 transition-all cursor-pointer shadow-2xl"
          >
            <ChevronRight size={24} />
          </button>
        )}

        <img
          ref={imgRef}
          key={currentIndex}
          src={images[currentIndex]}
          alt={part.title || "Spare Part Image"}
          loading="eager"
          decoding="async"
          draggable={false}
          referrerPolicy="no-referrer"
          className="max-w-full max-h-full w-auto h-auto object-contain pointer-events-none select-none will-change-transform block m-auto"
          style={{
            maxWidth: "100vw",
            maxHeight: "100vh",
            objectFit: "contain",
            transform: `translate3d(${position.x}px, ${position.y}px, 0px) scale(${scale})`,
            transformOrigin: "center center"
          }}
        />
      </div>

      {/* 3. PAKKA REACT NATIVE BOTTOM BAR & THUMBNAIL STRIP */}
      {showDetails && (
        <div className="w-full bg-gradient-to-t from-black/90 via-black/70 to-transparent pt-6 pb-4 px-4 sm:px-6 flex flex-col gap-3 z-50 backdrop-blur-lg border-t border-white/10 transition-all">
          <div className="flex flex-row items-center justify-between">
            <div className="flex-1 min-w-0 pr-3">
              <h3 className="text-white text-sm sm:text-base font-bold truncate">
                {part.title || "Spare Part"}
              </h3>
              <p className="text-slate-400 text-xs truncate mt-0.5">
                {part.carBrand ? `${part.carBrand} ` : ""}{part.carModel || "Genuine OEM Part"} • {part.location || "India"}
              </p>
            </div>
            {part.price !== undefined && part.price !== null && (
              <div className="px-3.5 py-1.5 rounded-xl bg-blue-600 text-white font-extrabold text-sm sm:text-base shadow-lg shrink-0">
                ₹{Number(part.price || 0).toLocaleString("en-IN")}
              </div>
            )}
          </div>

          {images.length > 1 && (
            <div className="flex items-center gap-2 overflow-x-auto py-1 scrollbar-none">
              {images.map((imgUrl, idx) => (
                <button
                  key={idx}
                  type="button"
                  onClick={() => handleSelectIndex(idx)}
                  className={`relative w-14 h-14 rounded-xl overflow-hidden shrink-0 transition-all cursor-pointer border-2 shadow-md ${
                    idx === currentIndex
                      ? "border-blue-500 scale-105 shadow-blue-500/30"
                      : "border-white/20 opacity-60 hover:opacity-100"
                  }`}
                >
                  <img
                    src={imgUrl}
                    alt=""
                    className="w-full h-full object-cover"
                    loading="lazy"
                    referrerPolicy="no-referrer"
                  />
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
