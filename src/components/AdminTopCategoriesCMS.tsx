import React, { useState } from "react";
import { TopCategory } from "../types";
import { createTopCategory, updateTopCategory, deleteTopCategory, reorderTopCategories } from "../lib/firebase";
import { Plus, Edit2, Trash2, Save, X, GripVertical } from "lucide-react";

export default function AdminTopCategoriesCMS({
  topCategories,
  showToast
}: {
  topCategories: TopCategory[];
  showToast: (m: string, t: "success" | "error") => void;
}) {
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<{name: string, icon: string, iconColor: string, isActive: boolean}>({
    name: "", icon: "", iconColor: "#0F172A", isActive: true
  });
  const [isAdding, setIsAdding] = useState(false);

  const handleSave = async () => {
    try {
      if (editingId) {
        await updateTopCategory(editingId, form);
        showToast("Category updated", "success");
      } else {
        await createTopCategory({ ...form, order: topCategories.length });
        showToast("Category created", "success");
      }
      setEditingId(null);
      setIsAdding(false);
      setForm({ name: "", icon: "", iconColor: "#0F172A", isActive: true });
    } catch (e: any) {
      showToast(e.message, "error");
    }
  };

  const handleEdit = (cat: TopCategory) => {
    setEditingId(cat.id);
    setIsAdding(true);
    setForm({ name: cat.name, icon: cat.icon, iconColor: cat.iconColor, isActive: cat.isActive });
  };

  const handleDelete = async (id: string) => {
    if(confirm("Are you sure?")) {
      await deleteTopCategory(id);
      showToast("Deleted", "success");
    }
  };

  const moveUp = async (index: number) => {
    if (index === 0) return;
    const newArr = [...topCategories];
    [newArr[index - 1], newArr[index]] = [newArr[index], newArr[index - 1]];
    const updates = newArr.map((cat, i) => ({ id: cat.id, order: i }));
    await reorderTopCategories(updates);
  };

  const moveDown = async (index: number) => {
    if (index === topCategories.length - 1) return;
    const newArr = [...topCategories];
    [newArr[index + 1], newArr[index]] = [newArr[index], newArr[index + 1]];
    const updates = newArr.map((cat, i) => ({ id: cat.id, order: i }));
    await reorderTopCategories(updates);
  };

  const seedCategories = async () => {
    if (!confirm("This will add the default 5 categories. Proceed?")) return;
    const defaults = [
      { name: 'Engine & Parts', icon: 'engine', iconColor: '#0F172A', isActive: true },
      { name: 'Body Parts', icon: 'car-door', iconColor: '#0F172A', isActive: true },
      { name: 'Electricals', icon: 'lightning-bolt', iconColor: '#0066FF', isActive: true },
      { name: 'Suspension', icon: 'car-brake-alert', iconColor: '#0F172A', isActive: true },
      { name: 'Exhaust', icon: 'needle', iconColor: '#0F172A', isActive: true },
    ];
    for (let i = 0; i < defaults.length; i++) {
      await createTopCategory({ ...defaults[i], order: topCategories.length + i });
    }
    showToast("Defaults seeded", "success");
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center bg-white p-4 rounded-xl border border-slate-200">
        <div>
          <h3 className="font-bold text-slate-800">Top Categories ({topCategories.length})</h3>
          <p className="text-xs text-slate-500">Manage the horizontal categories on the mobile app home screen.</p>
        </div>
        <div className="flex gap-2">
          <button onClick={seedCategories} className="px-4 py-2 bg-slate-100 text-slate-700 text-xs font-bold rounded-lg hover:bg-slate-200">
            Seed Defaults
          </button>
          <button onClick={() => { setIsAdding(true); setEditingId(null); setForm({name: "", icon: "", iconColor: "#0F172A", isActive: true}) }} className="px-4 py-2 bg-blue-600 text-white text-xs font-bold rounded-lg hover:bg-blue-700 flex items-center gap-1">
            <Plus size={14} /> Add New
          </button>
        </div>
      </div>

      {isAdding && (
        <div className="bg-white p-4 rounded-xl border border-slate-200 space-y-4">
          <h4 className="font-bold text-sm">{editingId ? 'Edit Category' : 'New Category'}</h4>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-600 mb-1">Name</label>
              <input type="text" value={form.name} onChange={e => setForm({...form, name: e.target.value})} className="w-full text-sm p-2 border border-slate-200 rounded-lg" placeholder="e.g. Tyres" />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-600 mb-1">Material Icon Name</label>
              <input type="text" value={form.icon} onChange={e => setForm({...form, icon: e.target.value})} className="w-full text-sm p-2 border border-slate-200 rounded-lg" placeholder="e.g. car-tire" />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-600 mb-1">Icon Color (Hex)</label>
              <input type="text" value={form.iconColor} onChange={e => setForm({...form, iconColor: e.target.value})} className="w-full text-sm p-2 border border-slate-200 rounded-lg" placeholder="e.g. #0F172A" />
            </div>
            <div className="flex items-center mt-6">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" checked={form.isActive} onChange={e => setForm({...form, isActive: e.target.checked})} className="w-4 h-4" />
                <span className="text-sm font-bold text-slate-700">Active</span>
              </label>
            </div>
          </div>
          <div className="flex gap-2 justify-end">
            <button onClick={() => setIsAdding(false)} className="px-4 py-2 text-slate-500 font-bold text-xs hover:bg-slate-100 rounded-lg">Cancel</button>
            <button onClick={handleSave} className="px-4 py-2 bg-green-600 text-white font-bold text-xs rounded-lg hover:bg-green-700">Save Category</button>
          </div>
        </div>
      )}

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {topCategories.length === 0 ? (
          <div className="p-8 text-center text-slate-500 text-sm">No categories found. Click Seed Defaults to add the initial 5.</div>
        ) : (
          <div className="divide-y divide-slate-100">
            {topCategories.map((cat, index) => (
              <div key={cat.id} className="p-4 flex items-center justify-between hover:bg-slate-50 transition-colors">
                <div className="flex items-center gap-4">
                  <div className="flex flex-col gap-1">
                    <button onClick={() => moveUp(index)} disabled={index === 0} className="text-slate-300 hover:text-slate-600 disabled:opacity-30"><GripVertical size={14}/></button>
                    <button onClick={() => moveDown(index)} disabled={index === topCategories.length - 1} className="text-slate-300 hover:text-slate-600 disabled:opacity-30"><GripVertical size={14}/></button>
                  </div>
                  <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: cat.iconColor + '20' }}>
                    {/* Just a placeholder circle in web */}
                    <div className="w-4 h-4 rounded-full" style={{ backgroundColor: cat.iconColor }}></div>
                  </div>
                  <div>
                    <h4 className="font-bold text-slate-800 text-sm">{cat.name}</h4>
                    <p className="text-xs text-slate-500">Icon: {cat.icon} | Color: {cat.iconColor}</p>
                  </div>
                  {!cat.isActive && <span className="px-2 py-1 bg-red-100 text-red-700 text-[10px] font-bold rounded-md ml-2">Hidden</span>}
                </div>
                <div className="flex gap-2">
                  <button onClick={() => handleEdit(cat)} className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg"><Edit2 size={16}/></button>
                  <button onClick={() => handleDelete(cat.id)} className="p-2 text-red-600 hover:bg-red-50 rounded-lg"><Trash2 size={16}/></button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
