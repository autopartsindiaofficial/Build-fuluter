import React, { useState, useEffect } from "react";
import { signInWithGoogle, signInWithEmail, signUpWithEmail, sendPasswordReset } from "../lib/firebase";
import { User } from "../types";
import { motion, AnimatePresence } from "motion/react";
import { 
  CheckCircle2, 
  X, 
  AlertCircle, 
  Mail, 
  Lock, 
  Eye, 
  EyeOff, 
  User as UserIcon, 
  ChevronRight,
  ShieldCheck
} from "lucide-react";

interface AuthScreenProps {
  onAuthSuccess: (user: User) => void;
  logoutMessage?: string | null;
  onClearLogoutMessage?: () => void;
}

export default function AuthScreen({ onAuthSuccess, logoutMessage, onClearLogoutMessage }: AuthScreenProps) {
  const [mode, setMode] = useState<"signin" | "signup">("signin");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [googleLoading, setGoogleLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successInfo, setSuccessInfo] = useState<string | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(logoutMessage || null);
  const [showForgotModal, setShowForgotModal] = useState(false);
  const [forgotEmail, setForgotEmail] = useState("");
  const [forgotLoading, setForgotLoading] = useState(false);
  const [legalModal, setLegalModal] = useState<"terms" | "privacy" | null>(null);

  // Sync logout message into temporary floating toast
  useEffect(() => {
    if (logoutMessage) {
      setToastMessage(logoutMessage);
      const timer = setTimeout(() => {
        setToastMessage(null);
        if (onClearLogoutMessage) onClearLogoutMessage();
      }, 4000);
      return () => clearTimeout(timer);
    }
  }, [logoutMessage, onClearLogoutMessage]);

  const handleGoogleSignIn = async () => {
    if (loading || googleLoading) return;
    setGoogleLoading(true);
    setError(null);
    try {
      const user = await signInWithGoogle();
      onAuthSuccess(user);
    } catch (err: any) {
      console.warn("Google Sign-In notice:", err?.message || err);
      let friendlyMessage = "Failed to sign in with Google. Please try again.";
      const errCode = err?.code;
      const rawMsg = String(err?.message || err || "");

      if (errCode === "auth/popup-closed-by-user") {
        friendlyMessage = "Sign-in window was closed. Please try again.";
      } else if (errCode === "auth/popup-blocked") {
        friendlyMessage = "Sign-in popup was blocked by your browser. Please allow popups for this site.";
      } else if (errCode === "auth/network-request-failed") {
        friendlyMessage = "Network connection failed. Please check your connection and try again.";
      } else if (rawMsg.includes("console.firebase.google.com") || rawMsg.includes("unauthorized-domain")) {
        friendlyMessage = "Google Sign-In is temporarily unavailable. Please try again in a moment.";
      } else if (rawMsg && !rawMsg.includes("http") && !rawMsg.includes("firebase") && !rawMsg.includes("Firebase")) {
        friendlyMessage = rawMsg;
      }
      setError(friendlyMessage);
    } finally {
      setGoogleLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (loading || googleLoading) return;

    if (!email.trim()) {
      setError("Please enter your email address.");
      return;
    }
    if (!password) {
      setError("Please enter your password.");
      return;
    }
    if (mode === "signup" && password.length < 6) {
      setError("Password must be at least 6 characters long.");
      return;
    }

    setLoading(true);
    setError(null);
    setSuccessInfo(null);

    try {
      if (mode === "signin") {
        const user = await signInWithEmail(email, password);
        onAuthSuccess(user);
      } else {
        const user = await signUpWithEmail(email, password, displayName);
        onAuthSuccess(user);
      }
    } catch (err: any) {
      console.warn("Auth error:", err);
      const code = err?.code || "";
      let msg = "Authentication failed. Please try again.";
      if (code === "auth/user-not-found" || code === "auth/wrong-password" || code === "auth/invalid-credential") {
        msg = "Invalid email or password. Please check and try again.";
      } else if (code === "auth/email-already-in-use") {
        msg = "This email is already registered. Please sign in instead.";
      } else if (code === "auth/invalid-email") {
        msg = "Please enter a valid email address.";
      } else if (code === "auth/weak-password") {
        msg = "Password should be at least 6 characters.";
      } else if (code === "auth/too-many-requests") {
        msg = "Too many failed attempts. Please try again in a few minutes.";
      } else if (err?.message) {
        msg = err.message;
      }
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!forgotEmail.trim()) {
      setError("Please enter your email address.");
      return;
    }
    setForgotLoading(true);
    setError(null);
    try {
      await sendPasswordReset(forgotEmail);
      setSuccessInfo("Password reset link sent to your email!");
      setShowForgotModal(false);
      setForgotEmail("");
    } catch (err: any) {
      setError(err?.message || "Failed to send reset link. Please check your email address.");
    } finally {
      setForgotLoading(false);
    }
  };

  return (
    <div 
      className="flex-1 flex flex-col bg-[#F3F4F6] min-h-screen relative select-none overflow-x-hidden overflow-y-auto"
      style={{ minHeight: "100dvh" }}
      id="auth-screen-container"
    >
      {/* Floating Logout / Notification Toast */}
      <AnimatePresence>
        {toastMessage && (
          <motion.div
            key="logout-toast"
            initial={{ opacity: 0, y: -20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -20, scale: 0.95 }}
            transition={{ duration: 0.25 }}
            className="fixed top-4 left-1/2 -translate-x-1/2 z-50 bg-white text-slate-900 text-xs font-semibold px-4 py-2.5 rounded-full shadow-xl flex items-center gap-2 max-w-sm w-[90%] border border-slate-100"
          >
            <CheckCircle2 size={16} className="text-emerald-500 shrink-0" />
            <span className="flex-1 truncate">{toastMessage}</span>
            <button
              onClick={() => {
                setToastMessage(null);
                if (onClearLogoutMessage) onClearLogoutMessage();
              }}
              className="text-slate-400 hover:text-slate-800 p-0.5 rounded-full cursor-pointer"
            >
              <X size={14} />
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* TOP SECTION: EXACT REFERENCE IMAGE HERO ARTWORK */}
      <div className="w-full relative bg-slate-900 overflow-hidden shrink-0">
        <picture className="w-full block">
          <source srcSet="/assets/signin_hero.webp" type="image/webp" />
          <img 
            src="/assets/signin_hero.png" 
            alt="Auto Parts India Marketplace" 
            className="w-full h-auto max-h-[300px] sm:max-h-[340px] object-cover sm:object-contain object-center pointer-events-none select-none block"
            draggable={false}
          />
        </picture>
        {/* Subtle bottom shadow overlay into white sheet */}
        <div className="absolute inset-x-0 bottom-0 h-4 bg-gradient-to-t from-black/10 to-transparent pointer-events-none" />
      </div>

      {/* BOTTOM SECTION: WHITE SHEET SIGN-IN CARD MATCHING REFERENCE IMAGE */}
      <div className="flex-1 bg-white rounded-t-[28px] -mt-3.5 pt-6 pb-8 px-6 sm:px-8 shadow-2xl relative z-10 flex flex-col justify-between max-w-md mx-auto w-full">
        <div>
          {/* Header Typography matching reference image */}
          <div className="mb-5">
            <h1 className="text-[22px] sm:text-[25px] leading-tight text-slate-800 font-semibold tracking-tight">
              {mode === "signin" ? "Welcome to" : "Create Account on"}
            </h1>
            <h2 className="text-[24px] sm:text-[27px] leading-tight text-slate-950 font-black tracking-tight">
              Auto Parts India
            </h2>
            <p className="text-slate-500 text-xs sm:text-[13px] font-medium mt-1">
              Buy and sell new & used auto spare parts
            </p>
          </div>

          {/* Error & Success Alerts */}
          {error && (
            <motion.div
              initial={{ opacity: 0, y: -6 }}
              animate={{ opacity: 1, y: 0 }}
              className="mb-4 p-3 bg-red-50 border border-red-200 rounded-xl text-xs text-red-700 flex items-start gap-2.5"
            >
              <AlertCircle size={16} className="shrink-0 text-red-500 mt-0.5" />
              <span className="leading-snug flex-1 font-medium">{error}</span>
              <button onClick={() => setError(null)} className="text-red-400 hover:text-red-700">
                <X size={14} />
              </button>
            </motion.div>
          )}

          {successInfo && (
            <motion.div
              initial={{ opacity: 0, y: -6 }}
              animate={{ opacity: 1, y: 0 }}
              className="mb-4 p-3 bg-emerald-50 border border-emerald-200 rounded-xl text-xs text-emerald-800 flex items-start gap-2.5"
            >
              <CheckCircle2 size={16} className="shrink-0 text-emerald-600 mt-0.5" />
              <span className="leading-snug flex-1 font-medium">{successInfo}</span>
              <button onClick={() => setSuccessInfo(null)} className="text-emerald-400 hover:text-emerald-700">
                <X size={14} />
              </button>
            </motion.div>
          )}

          {/* 1. GOOGLE SIGN IN BUTTON MATCHING REFERENCE IMAGE */}
          <button
            type="button"
            onClick={handleGoogleSignIn}
            disabled={googleLoading || loading}
            className="w-full h-[50px] bg-white hover:bg-slate-50 active:scale-[0.99] border border-slate-200/90 text-slate-800 font-bold rounded-xl px-4 text-sm sm:text-[15px] flex items-center justify-between transition-all shadow-sm disabled:opacity-60 cursor-pointer"
            id="btn-google-signin"
          >
            <div className="flex items-center gap-3">
              {googleLoading ? (
                <span className="w-5 h-5 border-2 border-[#006DFD] border-t-transparent rounded-full animate-spin" />
              ) : (
                <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" />
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" />
                </svg>
              )}
              <span className="font-semibold text-slate-800 tracking-tight">
                {googleLoading ? "Connecting to Google..." : "Continue with Google"}
              </span>
            </div>
            <ChevronRight size={18} className="text-slate-400 shrink-0" />
          </button>

          {/* 2. OR DIVIDER */}
          <div className="flex items-center gap-3 my-4">
            <div className="h-px bg-slate-200 flex-1" />
            <span className="text-[11px] font-bold text-slate-400 uppercase tracking-widest">OR</span>
            <div className="h-px bg-slate-200 flex-1" />
          </div>

          {/* 3. EMAIL & PASSWORD FORM */}
          <form onSubmit={handleSubmit} className="flex flex-col gap-3">
            {mode === "signup" && (
              <div className="relative">
                <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">
                  <UserIcon size={18} />
                </div>
                <input
                  type="text"
                  value={displayName}
                  onChange={(e) => setDisplayName(e.target.value)}
                  placeholder="Full Name"
                  className="w-full h-12 pl-11 pr-4 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-sm focus:bg-white focus:border-[#006DFD] focus:ring-2 focus:ring-[#006DFD]/20 outline-none transition font-medium"
                />
              </div>
            )}

            <div className="relative">
              <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">
                <Mail size={18} />
              </div>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Email address"
                required
                className="w-full h-12 pl-11 pr-4 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-sm focus:bg-white focus:border-[#006DFD] focus:ring-2 focus:ring-[#006DFD]/20 outline-none transition font-medium"
              />
            </div>

            <div className="relative">
              <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">
                <Lock size={18} />
              </div>
              <input
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Password"
                required
                className="w-full h-12 pl-11 pr-11 bg-slate-50 border border-slate-200 rounded-xl text-slate-900 text-sm focus:bg-white focus:border-[#006DFD] focus:ring-2 focus:ring-[#006DFD]/20 outline-none transition font-medium"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 p-1 cursor-pointer"
                tabIndex={-1}
              >
                {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>

            {/* Forgot Password Link */}
            {mode === "signin" && (
              <div className="flex justify-end -mt-1">
                <button
                  type="button"
                  onClick={() => {
                    setForgotEmail(email);
                    setShowForgotModal(true);
                  }}
                  className="text-xs font-semibold text-[#006DFD] hover:underline cursor-pointer"
                >
                  Forgot password?
                </button>
              </div>
            )}

            {/* 4. PRIMARY BLUE BUTTON MATCHING REFERENCE IMAGE */}
            <button
              type="submit"
              disabled={loading || googleLoading}
              className="w-full h-[50px] bg-[#006DFD] hover:bg-[#005cd9] active:scale-[0.99] text-white font-bold rounded-xl px-4 text-sm sm:text-[15px] flex items-center justify-between transition-all shadow-md shadow-blue-500/20 disabled:opacity-70 cursor-pointer mt-1"
              id="btn-primary-auth"
            >
              <span className="font-bold tracking-tight">
                {loading 
                  ? (mode === "signin" ? "Signing In..." : "Creating Account...") 
                  : (mode === "signin" ? "Sign In" : "Create Account")
                }
              </span>
              {loading ? (
                <span className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <ChevronRight size={19} className="text-white/90" />
              )}
            </button>
          </form>

          {/* Toggle between Sign In & Sign Up */}
          <div className="mt-4 text-center">
            {mode === "signin" ? (
              <p className="text-xs text-slate-500 font-medium">
                Don’t have an account?{" "}
                <button
                  type="button"
                  onClick={() => {
                    setMode("signup");
                    setError(null);
                  }}
                  className="font-bold text-[#006DFD] hover:underline cursor-pointer"
                >
                  Sign Up
                </button>
              </p>
            ) : (
              <p className="text-xs text-slate-500 font-medium">
                Already have an account?{" "}
                <button
                  type="button"
                  onClick={() => {
                    setMode("signin");
                    setError(null);
                  }}
                  className="font-bold text-[#006DFD] hover:underline cursor-pointer"
                >
                  Sign In
                </button>
              </p>
            )}
          </div>
        </div>

        {/* 5. LEGAL NOTICE MATCHING REFERENCE IMAGE FOOTER */}
        <div className="mt-6 pt-4 border-t border-slate-100 text-center">
          <p className="text-[11px] sm:text-xs text-slate-400 font-normal leading-relaxed">
            By signing in, you agree to our{" "}
            <button
              type="button"
              onClick={() => setLegalModal("terms")}
              className="text-slate-600 hover:text-slate-900 underline font-medium cursor-pointer"
            >
              Terms of Service
            </button>{" "}
            and{" "}
            <button
              type="button"
              onClick={() => setLegalModal("privacy")}
              className="text-slate-600 hover:text-slate-900 underline font-medium cursor-pointer"
            >
              Privacy Policy
            </button>
          </p>
        </div>
      </div>

      {/* Forgot Password Modal */}
      <AnimatePresence>
        {showForgotModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-2xl relative"
            >
              <button
                onClick={() => setShowForgotModal(false)}
                className="absolute top-4 right-4 text-slate-400 hover:text-slate-600 p-1"
              >
                <X size={18} />
              </button>
              <h3 className="text-lg font-bold text-slate-900 mb-1">Reset Password</h3>
              <p className="text-xs text-slate-500 mb-4">
                Enter your registered email address and we'll send you a link to reset your password.
              </p>
              <form onSubmit={handleForgotPassword} className="flex flex-col gap-3">
                <input
                  type="email"
                  value={forgotEmail}
                  onChange={(e) => setForgotEmail(e.target.value)}
                  placeholder="Enter email address"
                  required
                  className="w-full h-11 px-3.5 bg-slate-50 border border-slate-200 rounded-xl text-sm outline-none focus:border-[#006DFD]"
                />
                <button
                  type="submit"
                  disabled={forgotLoading}
                  className="w-full h-11 bg-[#006DFD] text-white font-bold rounded-xl text-sm shadow-md hover:bg-blue-600 disabled:opacity-60 cursor-pointer"
                >
                  {forgotLoading ? "Sending Link..." : "Send Reset Link"}
                </button>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Terms / Privacy Modal */}
      <AnimatePresence>
        {legalModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="bg-white rounded-2xl p-6 max-w-md w-full shadow-2xl relative max-h-[80vh] flex flex-col"
            >
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2">
                  <ShieldCheck size={20} className="text-[#006DFD]" />
                  <h3 className="text-base font-bold text-slate-900">
                    {legalModal === "terms" ? "Terms of Service" : "Privacy Policy"}
                  </h3>
                </div>
                <button
                  onClick={() => setLegalModal(null)}
                  className="text-slate-400 hover:text-slate-600 p-1"
                >
                  <X size={18} />
                </button>
              </div>
              <div className="flex-1 overflow-y-auto py-4 text-xs text-slate-600 space-y-3 leading-relaxed">
                {legalModal === "terms" ? (
                  <>
                    <p><strong>1. Acceptance:</strong> By accessing or using Auto Parts India, you agree to comply with all applicable automobile marketplace policies.</p>
                    <p><strong>2. Genuine Parts:</strong> Sellers certify that listed auto spare parts are genuine, accurately described, and compliant with safety specifications.</p>
                    <p><strong>3. Transactions:</strong> Buyers and sellers conduct peer-to-peer discussions via in-app verified chat or calls directly.</p>
                    <p><strong>4. Fair Marketplace:</strong> Spam, fraudulent listings, stolen equipment, and harassment are strictly prohibited.</p>
                  </>
                ) : (
                  <>
                    <p><strong>1. Data Protection:</strong> We protect your profile and contact information using secure 256-bit encryption.</p>
                    <p><strong>2. Contact Privacy:</strong> Phone numbers and chat messages are encrypted and only accessible to relevant transaction counterparties.</p>
                    <p><strong>3. Location Services:</strong> Location coordinates are used exclusively to calculate distance to nearest auto spare parts.</p>
                  </>
                )}
              </div>
              <button
                onClick={() => setLegalModal(null)}
                className="w-full h-10 bg-slate-100 hover:bg-slate-200 text-slate-800 font-bold rounded-xl text-xs mt-2"
              >
                Close
              </button>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
