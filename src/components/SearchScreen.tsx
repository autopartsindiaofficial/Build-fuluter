import React, { useState, useMemo } from "react";
import {
  Search,
  SlidersHorizontal,
  X,
  MapPin,
  Car,
  Tag,
  ChevronDown,
  Layers,
  Heart,
  MessageSquare,
  Sparkles,
  RotateCcw,
  Check
} from "lucide-react";
import { SparePart, User, CAR_PART_CATEGORIES } from "../types";
import { subscribeToTaxonomyConfig, FullTaxonomyConfig } from "../lib/firebase";
import UserAvatar from "./UserAvatar";
import PullToRefresh from "./PullToRefresh";
import { useLanguage } from "../lib/LanguageContext";
import { translateDynamic } from "../lib/translations";
import { formatLocationBadgeWithDistance, calculateDistance, LatLng } from "../utils/locationHelper";
import { matchPartSearch, parseCreatedAt } from "../utils/searchHelper";
import { matchesCategoryFilter } from "../utils/categoryMatcher";
import BrandLogo from "./BrandLogo";
import { Category3DIcon } from "./Category3DIcon";

interface SearchScreenProps {
  parts: SparePart[];
  partsLoading?: boolean;
  currentUser: User | null;
  favorites: string[];
  onFavoriteToggle?: (partId: string) => void;
  onViewPart?: (part: SparePart) => void;
  onStartChat?: (part: SparePart) => void;
  onOpenUserProfile?: (userId: string, userName: string) => void;
  onRefresh?: () => Promise<void> | void;
}

export default function SearchScreen({
  parts,
  partsLoading = false,
  currentUser,
  favorites,
  onFavoriteToggle,
  onViewPart,
  onStartChat,
  onOpenUserProfile,
  onRefresh
}: SearchScreenProps) {
  const { t, language } = useLanguage();

  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All Categories");
  const [selectedBrand, setSelectedBrand] = useState("All Brands");
  const [selectedModel, setSelectedModel] = useState("All Models");
  const [selectedCondition, setSelectedCondition] = useState("All Conditions");
  const [selectedState, setSelectedState] = useState("All States");
  const [selectedDistrict, setSelectedDistrict] = useState("All Districts");
  const [sortBy, setSortBy] = useState<"newest" | "price_low" | "price_high">("newest");
  const [isFilterSheetOpen, setIsFilterSheetOpen] = useState(false);

  const [taxonomy, setTaxonomy] = useState<FullTaxonomyConfig>({
    categories: [],
    categoryImages: {},
    subcategories: {},
    brands: {},
    brandLogos: {},
    variants: {},
    states: [],
    districts: {},
    cities: {},
    locations: []
  });

  React.useEffect(() => {
    const unsub = subscribeToTaxonomyConfig((config) => {
      setTaxonomy(config);
    });
    return () => unsub();
  }, []);

  const activeFiltersCount = [
    selectedCategory !== "All Categories",
    selectedBrand !== "All Brands",
    selectedModel !== "All Models",
    selectedCondition !== "All Conditions",
    selectedState !== "All States",
    selectedDistrict !== "All Districts"
  ].filter(Boolean).length;

  const resetFilters = () => {
    setSearchQuery("");
    setSelectedCategory("All Categories");
    setSelectedBrand("All Brands");
    setSelectedModel("All Models");
    setSelectedCondition("All Conditions");
    setSelectedState("All States");
    setSelectedDistrict("All Districts");
    setSortBy("newest");
  };

  const filteredParts = useMemo(() => {
    const scoredList: { part: SparePart; score: number }[] = [];

    for (const part of parts) {
      // Exclude sold or deleted parts from search
      const isSold = part.sold === true || part.status === "sold";
      const isDeleted = (part as any).isDeleted === true || (part as any).status === "deleted";
      if (isSold || isDeleted) continue;

      // Search text query matching & scoring
      let searchScore = 0;
      if (searchQuery.trim()) {
        const res = matchPartSearch(part, searchQuery.trim());
        if (!res.matches) continue;
        searchScore = res.score;
      }

      // Category filter
      if (selectedCategory !== "All Categories" && selectedCategory !== "All") {
        if (!matchesCategoryFilter(part, selectedCategory)) continue;
      }

      // Brand filter
      if (selectedBrand !== "All Brands" && selectedBrand !== "All") {
        const sBrand = selectedBrand.toLowerCase().trim();
        const pBrand = (part.carBrand || (part as any).brand || (part as any).make || "").toLowerCase().trim();
        const pTitle = (part.title || "").toLowerCase().trim();
        const pModel = (part.carModel || (part as any).model || "").toLowerCase().trim();
        const brandMatch =
          pBrand === sBrand ||
          (pBrand && (pBrand.includes(sBrand) || sBrand.includes(pBrand))) ||
          pTitle.includes(sBrand) ||
          pModel.includes(sBrand);
        if (!brandMatch) continue;
      }

      // Model filter
      if (selectedModel !== "All Models" && selectedModel !== "All") {
        const sModel = selectedModel.toLowerCase().trim();
        const pModel = (part.carModel || (part as any).model || "").toLowerCase().trim();
        const pTitle = (part.title || "").toLowerCase().trim();
        const modelMatch = pModel === sModel || pModel.includes(sModel) || pTitle.includes(sModel);
        if (!modelMatch) continue;
      }

      // Condition filter
      if (selectedCondition !== "All Conditions" && selectedCondition !== "All") {
        const isNewSelected = selectedCondition.toLowerCase().includes("new");
        const isPartNew = (part.condition || "").toLowerCase().includes("new");
        if (isNewSelected && !isPartNew) continue;
        if (!isNewSelected && isPartNew) continue;
      }

      // State filter
      if (selectedState !== "All States") {
        const sState = selectedState.toLowerCase().trim();
        const locState = [
          part.state,
          part.location,
          part.city,
          part.district,
          part.area,
          (part as any).sellerState
        ].filter(Boolean).join(" ").toLowerCase();
        if (!locState.includes(sState)) continue;
      }

      // District filter
      if (selectedDistrict !== "All Districts") {
        const sDist = selectedDistrict.toLowerCase().trim();
        const locDist = [
          part.district,
          part.city,
          part.location,
          part.area,
          (part as any).sellerDistrict,
          (part as any).sellerCity
        ].filter(Boolean).join(" ").toLowerCase();
        if (!locDist.includes(sDist)) continue;
      }

      scoredList.push({ part, score: searchScore });
    }

    return scoredList.sort((a, b) => {
      if (searchQuery.trim() && sortBy === "newest") {
        if (b.score !== a.score) {
          return b.score - a.score;
        }
      }
      if (sortBy === "price_low") return a.part.price - b.part.price;
      if (sortBy === "price_high") return b.part.price - a.part.price;
      return parseCreatedAt(b.part.createdAt) - parseCreatedAt(a.part.createdAt);
    }).map(item => item.part);
  }, [
    parts,
    searchQuery,
    selectedCategory,
    selectedBrand,
    selectedModel,
    selectedCondition,
    selectedState,
    selectedDistrict,
    sortBy
  ]);

  const isSearchActive = Boolean(
    searchQuery.trim() ||
    (selectedCategory !== "All Categories" && selectedCategory !== "All") ||
    (selectedBrand !== "All Brands" && selectedBrand !== "All") ||
    (selectedModel !== "All Models" && selectedModel !== "All") ||
    selectedState !== "All States" ||
    selectedDistrict !== "All Districts"
  );

  const { localParts, nearbyParts } = useMemo(() => {
    const userCity = (localStorage.getItem("autoparts_selected_district") || localStorage.getItem("autoparts_user_area") || selectedDistrict || "").toLowerCase().trim();
    const userLat = parseFloat(localStorage.getItem("autoparts_user_lat") || "0");
    const userLng = parseFloat(localStorage.getItem("autoparts_user_lng") || "0");
    const hasUserCoords = userLat !== 0 && userLng !== 0;

    const locals: SparePart[] = [];
    const nearbys: SparePart[] = [];

    for (const part of filteredParts) {
      const partLoc = [part.location, part.district, part.city].filter(Boolean).join(" ").toLowerCase();
      let isLocal = false;

      if (userCity && userCity !== "all districts" && userCity !== "all india") {
        if (partLoc.includes(userCity)) {
          isLocal = true;
        }
      }

      if (!isLocal && hasUserCoords && part.lat && part.lng) {
        const d = calculateDistance(userLat, userLng, part.lat, part.lng);
        if (d <= 25) {
          isLocal = true;
        }
      }

      if (isLocal) {
        locals.push(part);
      } else {
        nearbys.push(part);
      }
    }

    if (hasUserCoords && sortBy === "newest") {
      nearbys.sort((a, b) => {
        const distA = a.lat && a.lng ? calculateDistance(userLat, userLng, a.lat, a.lng) : 99999;
        const distB = b.lat && b.lng ? calculateDistance(userLat, userLng, b.lat, b.lng) : 99999;
        return distA - distB;
      });
    }

    return { localParts: locals, nearbyParts: nearbys };
  }, [filteredParts, selectedDistrict, sortBy]);

  const renderRectangularCard = (part: SparePart, isLocal: boolean) => {
    const isFavorite = favorites.includes(part.id);
    const locBadge = formatLocationBadgeWithDistance(part);

    return (
      <div
        key={part.id}
        onClick={() => onViewPart && onViewPart(part)}
        className="bg-white dark:bg-slate-800 border border-slate-200/80 dark:border-slate-700/80 rounded-2xl overflow-hidden flex cursor-pointer active:scale-[0.99] transition-all shadow-xs hover:shadow-md p-2 gap-3"
      >
        {/* Rectangular Image Box (Sevvagam) */}
        <div className="relative w-28 h-28 shrink-0 bg-slate-900 rounded-xl overflow-hidden">
          <img
            src={part.imageUrl || (part.imageUrls && part.imageUrls[0]) || "https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&q=80&w=400"}
            alt={part.title}
            className="w-full h-full object-cover object-center"
            loading="lazy"
          />
          {part.sold && (
            <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
              <span className="text-[10px] font-black tracking-wider text-white bg-red-600 px-2 py-0.5 rounded">SOLD</span>
            </div>
          )}
          <span className="absolute top-1.5 left-1.5 text-[9px] font-extrabold px-1.5 py-0.5 rounded bg-black/60 backdrop-blur-xs text-white">
            {part.condition.includes("New") ? "New" : "Used"}
          </span>
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              if (onFavoriteToggle) onFavoriteToggle(part.id);
            }}
            className="absolute top-1.5 right-1.5 p-1 text-white hover:scale-110 active:scale-90 transition-transform cursor-pointer drop-shadow-md"
            aria-label="Toggle Favorite"
          >
            <Heart
              size={15}
              fill={isFavorite ? "#EF4444" : "none"}
              className={isFavorite ? "text-red-500 stroke-red-500" : "text-white stroke-white"}
              strokeWidth={2.2}
            />
          </button>
        </div>

        {/* Content Details on Right */}
        <div className="flex-1 flex flex-col justify-between py-0.5 min-w-0">
          <div>
            <h4 className="text-xs font-black text-slate-900 dark:text-white line-clamp-2 leading-snug">
              {part.title}
            </h4>
            <div className="inline-flex items-center gap-1 mt-1 px-1.5 py-0.5 rounded bg-blue-50 dark:bg-blue-950/40 text-blue-700 dark:text-blue-300 text-[10px] font-bold border border-blue-200/50">
              <Car size={10} className="shrink-0" />
              <span className="truncate max-w-[140px]">{part.carBrand} {part.carModel}</span>
            </div>
          </div>

          <div className="mt-1">
            <div className="text-sm font-black text-blue-600 dark:text-blue-400">
              ₹{part.price.toLocaleString("en-IN")}
            </div>
            <div className="flex items-center justify-between text-[10.5px] mt-0.5 text-slate-500 dark:text-slate-400">
              <span className="flex items-center gap-1 truncate max-w-[70%]">
                <MapPin size={10} className={isLocal ? "text-emerald-500 shrink-0" : "text-blue-500 shrink-0"} />
                <span className="truncate">{part.location || part.district || "India"}</span>
              </span>
              <span className={`text-[9.5px] font-bold px-1.5 py-0.5 rounded ${
                isLocal
                  ? "bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 border border-emerald-200/50"
                  : "bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400 border border-blue-200/50"
              }`}>
                {isLocal ? "Local" : locBadge.text.includes("km") ? locBadge.text.split("•")[1]?.trim() || "Nearby" : "Nearby"}
              </span>
            </div>
          </div>
        </div>
      </div>
    );
  };

  const quickCategories = [
    "All Categories",
    ...CAR_PART_CATEGORIES
  ];

  return (
    <div className="w-full h-full flex flex-col bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-slate-100 overflow-hidden select-none">
      {/* Native App Top Header */}
      <div className="shrink-0 bg-white dark:bg-slate-850 px-4 pt-3 pb-2 border-b border-slate-200/80 dark:border-slate-800 shadow-xs z-10">
        <div className="flex items-center justify-between gap-2 mb-2.5">
          <div>
            <h1 className="text-lg font-black tracking-tight text-slate-900 dark:text-white">
              {translateDynamic("Search Parts", language)}
            </h1>
            <p className="text-[11px] font-medium text-slate-500 dark:text-slate-400">
              {filteredParts.length} {translateDynamic("spare parts available", language)}
            </p>
          </div>

          {activeFiltersCount > 0 && (
            <button
              onClick={resetFilters}
              className="flex items-center gap-1 px-2.5 py-1 bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 text-[11px] font-bold rounded-full active:scale-95 transition-all"
            >
              <RotateCcw size={12} />
              <span>Reset</span>
            </button>
          )}
        </div>

        {/* Search Bar & Filter Button */}
        <div className="flex items-center gap-2">
          <div className="relative flex-1">
            <Search size={17} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={translateDynamic("Search brand, model, part name...", language)}
              className="w-full pl-9 pr-8 py-2.5 bg-slate-100 dark:bg-slate-800 text-slate-900 dark:text-white text-xs rounded-xl font-medium placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-600 transition-all border border-slate-200/60 dark:border-slate-700/60"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery("")}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
              >
                <X size={15} />
              </button>
            )}
          </div>

          <button
            onClick={() => setIsFilterSheetOpen(true)}
            className={`relative p-2.5 rounded-xl border flex items-center justify-center active:scale-95 transition-all ${
              activeFiltersCount > 0
                ? "bg-blue-600 border-blue-600 text-white shadow-sm"
                : "bg-slate-100 dark:bg-slate-800 border-slate-200/60 dark:border-slate-700/60 text-slate-700 dark:text-slate-300"
            }`}
            aria-label="Open Filters"
          >
            <SlidersHorizontal size={18} />
            {activeFiltersCount > 0 && (
              <span className="absolute -top-1 -right-1 bg-amber-400 text-slate-950 text-[9px] font-black w-4 h-4 rounded-full flex items-center justify-center">
                {activeFiltersCount}
              </span>
            )}
          </button>
        </div>

        {/* Quick Category Chips */}
        <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar pt-2.5 pb-1">
          {quickCategories.map((cat) => {
            const isSelected = selectedCategory === cat;
            return (
              <button
                key={cat}
                onClick={() => setSelectedCategory(isSelected ? "All Categories" : cat)}
                className={`shrink-0 px-3 py-1 rounded-full text-[11px] font-bold transition-all active:scale-95 ${
                  isSelected
                    ? "bg-blue-600 text-white shadow-xs"
                    : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700 border border-slate-200/50 dark:border-slate-700/50"
                }`}
              >
                {cat === "All Categories" ? translateDynamic("All", language) : cat}
              </button>
            );
          })}
        </div>
      </div>

      {/* Main Results Container with Native Pull to Refresh */}
      <div className="flex-1 min-h-0 overflow-hidden relative">
        <PullToRefresh
          onRefresh={async () => {
            if (onRefresh) await onRefresh();
          }}
          className="px-3 py-3"
        >
          {!isSearchActive ? (
            <div className="space-y-6 pb-20 pt-1">
              {/* 1. Explore by Categories with Logos/Icons */}
              <div>
                <div className="flex items-center justify-between mb-3 px-1">
                  <h3 className="text-sm font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-1.5">
                    <span className="w-1.5 h-4 bg-blue-600 rounded-full inline-block" />
                    <span>Explore by Categories</span>
                  </h3>
                </div>
                <div className="grid grid-cols-4 gap-2">
                  {CAR_PART_CATEGORIES.slice(0, 8).map((cat) => (
                    <button
                      key={cat}
                      onClick={() => setSelectedCategory(cat)}
                      className="flex flex-col items-center justify-center p-2.5 bg-white dark:bg-slate-800 border border-slate-200/70 dark:border-slate-700/70 rounded-2xl shadow-2xs hover:shadow-sm active:scale-95 transition-all text-center group cursor-pointer"
                    >
                      <div className="w-11 h-11 rounded-xl bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 flex items-center justify-center mb-1.5 group-hover:scale-110 transition-transform">
                        <Category3DIcon categoryName={cat} size={32} />
                      </div>
                      <span className="text-[10.5px] font-bold text-slate-800 dark:text-slate-200 line-clamp-1 leading-tight">
                        {cat}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {/* 2. Popular Car Brands with Logos */}
              <div>
                <div className="flex items-center justify-between mb-3 px-1">
                  <h3 className="text-sm font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-1.5">
                    <span className="w-1.5 h-4 bg-amber-500 rounded-full inline-block" />
                    <span>Popular Car Brands</span>
                  </h3>
                </div>
                <div className="grid grid-cols-4 gap-2">
                  {["Maruti Suzuki", "Hyundai", "Tata", "Mahindra", "Toyota", "Honda", "Kia", "Volkswagen"].map((brand) => (
                    <button
                      key={brand}
                      onClick={() => setSelectedBrand(brand)}
                      className="flex flex-col items-center justify-center p-2 bg-white dark:bg-slate-800 border border-slate-200/70 dark:border-slate-700/70 rounded-2xl shadow-2xs hover:shadow-sm active:scale-95 transition-all text-center cursor-pointer group"
                    >
                      <div className="w-11 h-11 flex items-center justify-center mb-1 group-hover:scale-110 transition-transform">
                        <BrandLogo brand={brand} size="sm" />
                      </div>
                      <span className="text-[10px] font-bold text-slate-700 dark:text-slate-300 line-clamp-1">
                        {brand}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              {/* 3. Browse by City / Location */}
              <div>
                <div className="flex items-center justify-between mb-2.5 px-1">
                  <h3 className="text-sm font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-1.5">
                    <span className="w-1.5 h-4 bg-emerald-500 rounded-full inline-block" />
                    <span>Browse by Location</span>
                  </h3>
                </div>
                <div className="flex flex-wrap gap-1.5">
                  {["Chennai", "Coimbatore", "Madurai", "Salem", "Trichy", "Tiruppur", "Erode", "Vellore", "Bengaluru"].map((city) => (
                    <button
                      key={city}
                      onClick={() => setSelectedDistrict(city)}
                      className="px-3 py-1.5 rounded-full text-xs font-bold bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 hover:border-blue-500 active:scale-95 transition-all flex items-center gap-1 cursor-pointer"
                    >
                      <MapPin size={11} className="text-blue-500" />
                      <span>{city}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* 4. Trending Searches */}
              <div>
                <h3 className="text-xs font-bold text-slate-500 dark:text-slate-400 mb-2 px-1 flex items-center gap-1">
                  <Sparkles size={12} className="text-amber-500" />
                  <span>Trending Searches</span>
                </h3>
                <div className="flex flex-wrap gap-1.5">
                  {["Swift Bumper", "Creta Headlight", "Thar Grille", "Innova Brake Disc", "Nexon Tail Light", "Brezza Mirror"].map((q) => (
                    <button
                      key={q}
                      onClick={() => setSearchQuery(q)}
                      className="px-2.5 py-1 rounded-xl text-[11px] font-medium bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 active:scale-95 transition-all cursor-pointer"
                    >
                      {q}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          ) : filteredParts.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 px-4 text-center">
              <div className="w-14 h-14 rounded-2xl bg-blue-50 dark:bg-blue-950/40 text-blue-600 dark:text-blue-400 flex items-center justify-center mb-3">
                <Search size={26} />
              </div>
              <h3 className="text-sm font-bold text-slate-800 dark:text-slate-200">
                {translateDynamic("No auto parts found", language)}
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 max-w-xs">
                {translateDynamic("Try adjusting your keyword or filter options to discover more listings.", language)}
              </p>
              {activeFiltersCount > 0 && (
                <button
                  onClick={resetFilters}
                  className="mt-4 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white text-xs font-bold rounded-xl active:scale-95 transition-transform"
                >
                  {translateDynamic("Clear All Filters", language)}
                </button>
              )}
            </div>
          ) : (
            <div className="flex flex-col gap-4 pb-20">
              {/* 1. User Location Ads (Shown First) */}
              {localParts.length > 0 && (
                <div>
                  <div className="flex items-center justify-between mb-2.5 px-1">
                    <span className="text-xs font-black text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
                      <span className="w-2 h-2 rounded-full bg-emerald-500" />
                      <span>Available in Your Location ({localParts.length})</span>
                    </span>
                    <span className="text-[10px] font-bold text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 px-2 py-0.5 rounded-full border border-emerald-200/50">
                      Local Matches
                    </span>
                  </div>
                  <div className="flex flex-col gap-2.5">
                    {localParts.map((part) => renderRectangularCard(part, true))}
                  </div>
                </div>
              )}

              {/* 2. Nearby Ads from Surrounding Areas (Shown Second, sorted by distance) */}
              {nearbyParts.length > 0 && (
                <div>
                  <div className="flex items-center justify-between mb-2.5 mt-2 px-1">
                    <span className="text-xs font-black text-slate-800 dark:text-slate-200 flex items-center gap-1.5">
                      <span className="w-2 h-2 rounded-full bg-blue-500" />
                      <span>Nearby Parts from Surrounding Areas ({nearbyParts.length})</span>
                    </span>
                    <span className="text-[10px] font-bold text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-950/40 px-2 py-0.5 rounded-full border border-blue-200/50">
                      Nearest First
                    </span>
                  </div>
                  <div className="flex flex-col gap-2.5">
                    {nearbyParts.map((part) => renderRectangularCard(part, false))}
                  </div>
                </div>
              )}
            </div>
          )}
        </PullToRefresh>
      </div>

      {/* Native Bottom Sheet Modal for Filters */}
      {isFilterSheetOpen && (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 backdrop-blur-xs animate-in fade-in duration-200"
          onClick={() => setIsFilterSheetOpen(false)}
        >
          <div
            className="w-full max-w-md bg-white dark:bg-slate-850 rounded-t-3xl shadow-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-250"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Top Sheet Drag Pill */}
            <div className="pt-3 pb-1 flex justify-center shrink-0">
              <div className="w-12 h-1.5 bg-slate-300 dark:bg-slate-700 rounded-full" />
            </div>

            {/* Header */}
            <div className="px-5 py-3 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between shrink-0">
              <h3 className="text-base font-black text-slate-900 dark:text-white">
                {translateDynamic("Filter Auto Parts", language)}
              </h3>
              <button
                onClick={() => setIsFilterSheetOpen(false)}
                className="p-1.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-500 hover:text-slate-900 dark:hover:text-white active:scale-95"
              >
                <X size={18} />
              </button>
            </div>

            {/* Filter Content */}
            <div className="flex-1 overflow-y-auto p-5 space-y-4 text-xs">
              {/* Brand Filter */}
              <div>
                <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                  Car Brand
                </label>
                <select
                  value={selectedBrand}
                  onChange={(e) => {
                    setSelectedBrand(e.target.value);
                    setSelectedModel("All Models");
                  }}
                  className="w-full px-3 py-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl font-semibold text-slate-800 dark:text-slate-200 focus:outline-none"
                >
                  <option value="All Brands">All Brands</option>
                  {Object.keys(taxonomy.brands || {}).map((b) => (
                    <option key={b} value={b}>{b}</option>
                  ))}
                </select>
              </div>

              {/* Model Filter */}
              {selectedBrand !== "All Brands" && taxonomy.brands[selectedBrand] && (
                <div>
                  <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                    Car Model
                  </label>
                  <select
                    value={selectedModel}
                    onChange={(e) => setSelectedModel(e.target.value)}
                    className="w-full px-3 py-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl font-semibold text-slate-800 dark:text-slate-200 focus:outline-none"
                  >
                    <option value="All Models">All Models</option>
                    {taxonomy.brands[selectedBrand].map((m) => (
                      <option key={m} value={m}>{m}</option>
                    ))}
                  </select>
                </div>
              )}

              {/* Category Filter */}
              <div>
                <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                  Part Category
                </label>
                <select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="w-full px-3 py-2.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl font-semibold text-slate-800 dark:text-slate-200 focus:outline-none"
                >
                  <option value="All Categories">All Categories</option>
                  {(taxonomy.categories && taxonomy.categories.length > 0 ? taxonomy.categories : CAR_PART_CATEGORIES).map((c) => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
              </div>

              {/* Condition Filter */}
              <div>
                <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                  Condition
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {["All Conditions", "Brand New", "Used (Good)"].map((cond) => (
                    <button
                      key={cond}
                      type="button"
                      onClick={() => setSelectedCondition(cond)}
                      className={`py-2 px-2 rounded-xl text-center font-bold text-[11px] border active:scale-95 transition-all ${
                        selectedCondition === cond
                          ? "bg-blue-600 border-blue-600 text-white"
                          : "bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300"
                      }`}
                    >
                      {cond === "All Conditions" ? "All" : cond}
                    </button>
                  ))}
                </div>
              </div>

              {/* Sort Order */}
              <div>
                <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                  Sort By
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {[
                    { id: "newest", label: "Newest" },
                    { id: "price_low", label: "Price: Low" },
                    { id: "price_high", label: "Price: High" }
                  ].map((s) => (
                    <button
                      key={s.id}
                      type="button"
                      onClick={() => setSortBy(s.id as any)}
                      className={`py-2 px-2 rounded-xl text-center font-bold text-[11px] border active:scale-95 transition-all ${
                        sortBy === s.id
                          ? "bg-blue-600 border-blue-600 text-white"
                          : "bg-slate-50 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-700 dark:text-slate-300"
                      }`}
                    >
                      {s.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Bottom Actions */}
            <div className="p-4 border-t border-slate-100 dark:border-slate-800 flex items-center gap-3 shrink-0 bg-slate-50 dark:bg-slate-900">
              <button
                onClick={resetFilters}
                className="px-4 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 font-bold text-slate-700 dark:text-slate-300 text-xs active:scale-95 transition-all"
              >
                Reset
              </button>
              <button
                onClick={() => setIsFilterSheetOpen(false)}
                className="flex-1 py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl shadow-md active:scale-95 transition-transform"
              >
                Show {filteredParts.length} Results
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
