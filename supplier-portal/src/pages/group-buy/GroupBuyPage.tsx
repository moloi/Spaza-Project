import { useState, useEffect, useCallback } from 'react';
import { Users, Package, TrendingUp, Clock, CheckCircle, AlertTriangle, ArrowRight } from 'lucide-react';
import api from '../../services/api';
import toast from 'react-hot-toast';

interface GroupBuy {
  id: string;
  title: string;
  description: string;
  targetQty: number;
  currentQty: number;
  originalPrice: number;
  discountPrice: number;
  discountPct: number;
  expiresAt: string;
  status: string;
  createdAt: string;
  productId: string;
  productName: string;
  createdByShopName: string;
  participantCount: number;
  progress: number;
  participants: { id: string; shopId: string; shopName: string; quantity: number; createdAt: string }[];
}

export default function GroupBuyPage() {
  const [deals, setDeals] = useState<GroupBuy[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'completed'>('all');
  const [selectedDeal, setSelectedDeal] = useState<GroupBuy | null>(null);

  const fetchDeals = useCallback(async () => {
    setLoading(true);
    try {
      const res = await api.get(`/supplier/group-buy?status=${filter}`);
      setDeals(res.data.data || []);
    } catch {
      toast.error('Failed to load group buys');
    } finally {
      setLoading(false);
    }
  }, [filter]);

  useEffect(() => { fetchDeals(); }, [fetchDeals]);

  const handleApprove = async (id: string) => {
    if (!confirm('Approve this group buy? Individual orders will be created for each participant.')) return;
    try {
      const res = await api.post(`/supplier/group-buy/${id}/approve`);
      toast.success(res.data.data?.Message || 'Group buy approved!');
      fetchDeals();
      setSelectedDeal(null);
    } catch (err: any) {
      toast.error(err.response?.data?.message || 'Failed to approve');
    }
  };

  const stats = {
    total: deals.length,
    active: deals.filter(d => d.status === 'active').length,
    completed: deals.filter(d => d.status === 'completed').length,
    totalUnits: deals.reduce((sum, d) => sum + d.currentQty, 0),
  };

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Group Buy Orders</h1>
          <p className="text-sm text-gray-500 mt-1">Spaza shops pool orders together for bulk discounts on your products</p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
        <StatCard icon={<Users size={20} />} label="Total Group Buys" value={stats.total} color="blue" />
        <StatCard icon={<Clock size={20} />} label="Active" value={stats.active} color="amber" />
        <StatCard icon={<CheckCircle size={20} />} label="Completed" value={stats.completed} color="green" />
        <StatCard icon={<Package size={20} />} label="Total Units" value={stats.totalUnits} color="purple" />
      </div>

      {/* Filter tabs */}
      <div className="flex gap-2 border-b border-gray-200 pb-3">
        {(['all', 'active', 'completed'] as const).map(f => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              filter === f ? 'bg-primary text-white shadow-sm' : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
          </button>
        ))}
      </div>

      {/* Deals list */}
      {loading ? (
        <div className="flex justify-center py-12"><div className="w-8 h-8 border-4 border-primary border-t-transparent rounded-full animate-spin" /></div>
      ) : deals.length === 0 ? (
        <div className="text-center py-16">
          <Users size={48} className="mx-auto text-gray-300 mb-4" />
          <p className="text-gray-500 font-medium">No group buys yet</p>
          <p className="text-sm text-gray-400 mt-1">When spaza shops create group buys for your products, they'll appear here</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {deals.map(deal => (
            <DealCard key={deal.id} deal={deal} onSelect={() => setSelectedDeal(deal)} onApprove={() => handleApprove(deal.id)} />
          ))}
        </div>
      )}

      {/* Detail Modal */}
      {selectedDeal && (
        <DealDetailModal deal={selectedDeal} onClose={() => setSelectedDeal(null)} onApprove={() => handleApprove(selectedDeal.id)} />
      )}
    </div>
  );
}

function StatCard({ icon, label, value, color }: { icon: React.ReactNode; label: string; value: number; color: string }) {
  const colors: Record<string, string> = {
    blue: 'bg-blue-50 text-blue-600',
    amber: 'bg-amber-50 text-amber-600',
    green: 'bg-green-50 text-green-600',
    purple: 'bg-purple-50 text-purple-600',
  };
  return (
    <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
      <div className="flex items-center gap-3">
        <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${colors[color]}`}>{icon}</div>
        <div>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
          <p className="text-xs text-gray-500">{label}</p>
        </div>
      </div>
    </div>
  );
}

function DealCard({ deal, onSelect, onApprove }: { deal: GroupBuy; onSelect: () => void; onApprove: () => void }) {
  const progress = deal.targetQty > 0 ? (deal.currentQty / deal.targetQty) * 100 : 0;
  const daysLeft = Math.max(0, Math.ceil((new Date(deal.expiresAt).getTime() - Date.now()) / 86400000));
  const isCompleted = deal.status === 'completed';
  const isExpired = daysLeft <= 0 && !isCompleted;

  return (
    <div className="bg-white rounded-xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden">
      {/* Header */}
      <div className={`px-5 py-4 border-b ${isCompleted ? 'bg-green-50 border-green-100' : 'bg-amber-50 border-amber-100'}`}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${isCompleted ? 'bg-green-100 text-green-600' : 'bg-amber-100 text-amber-600'}`}>
              <Users size={20} />
            </div>
            <div>
              <h3 className="font-semibold text-gray-900 text-sm">{deal.title}</h3>
              <p className="text-xs text-gray-500">{deal.productName}</p>
            </div>
          </div>
          <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
            isCompleted ? 'bg-green-100 text-green-700' : isExpired ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-700'
          }`}>
            {isCompleted ? '✓ Complete' : isExpired ? 'Expired' : `${daysLeft}d left`}
          </span>
        </div>
      </div>

      {/* Body */}
      <div className="p-5 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <span className="text-xs text-gray-400 line-through">R{deal.originalPrice.toFixed(2)}</span>
            <span className="ml-2 text-lg font-bold text-primary">R{deal.discountPrice.toFixed(2)}</span>
            <span className="ml-2 text-xs font-bold text-red-500 bg-red-50 px-2 py-0.5 rounded-full">-{deal.discountPct}%</span>
          </div>
          <div className="text-right">
            <p className="text-xs text-gray-400">Participants</p>
            <p className="text-sm font-bold text-gray-700">{deal.participantCount} shops</p>
          </div>
        </div>

        {/* Progress */}
        <div>
          <div className="flex justify-between text-xs text-gray-500 mb-1.5">
            <span>{deal.currentQty} / {deal.targetQty} units</span>
            <span className="font-bold text-primary">{progress.toFixed(0)}%</span>
          </div>
          <div className="w-full bg-gray-100 rounded-full h-2.5">
            <div
              className={`h-2.5 rounded-full transition-all ${isCompleted ? 'bg-green-500' : 'bg-primary'}`}
              style={{ width: `${Math.min(progress, 100)}%` }}
            />
          </div>
        </div>

        <div className="flex items-center justify-between text-xs text-gray-500">
          <span>Created by: {deal.createdByShopName}</span>
          <span>{new Date(deal.createdAt).toLocaleDateString()}</span>
        </div>

        {/* Actions */}
        <div className="flex gap-2 pt-2 border-t border-gray-100">
          <button onClick={onSelect} className="flex-1 text-sm font-medium text-gray-700 bg-gray-50 hover:bg-gray-100 py-2 rounded-lg transition-colors flex items-center justify-center gap-1.5">
            View Details <ArrowRight size={14} />
          </button>
          {deal.status === 'active' && progress >= 100 && (
            <button onClick={onApprove} className="flex-1 text-sm font-medium text-white bg-green-600 hover:bg-green-700 py-2 rounded-lg transition-colors flex items-center justify-center gap-1.5">
              <CheckCircle size={14} /> Approve & Create Orders
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function DealDetailModal({ deal, onClose, onApprove }: { deal: GroupBuy; onClose: () => void; onApprove: () => void }) {
  const progress = deal.targetQty > 0 ? (deal.currentQty / deal.targetQty) * 100 : 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={onClose}>
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-lg mx-4 max-h-[85vh] overflow-y-auto" onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div className="px-6 py-5 border-b bg-gradient-to-r from-amber-50 to-orange-50">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-amber-100 rounded-xl flex items-center justify-center">
              <Users size={24} className="text-amber-600" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-gray-900">{deal.title}</h2>
              <p className="text-sm text-gray-500">{deal.productName}</p>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 space-y-5">
          {/* Stats row */}
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-gray-50 rounded-lg p-3 text-center">
              <p className="text-lg font-bold text-primary">R{deal.discountPrice.toFixed(2)}</p>
              <p className="text-xs text-gray-500">Group Price</p>
            </div>
            <div className="bg-gray-50 rounded-lg p-3 text-center">
              <p className="text-lg font-bold text-gray-900">{deal.participantCount}</p>
              <p className="text-xs text-gray-500">Shops Joined</p>
            </div>
            <div className="bg-gray-50 rounded-lg p-3 text-center">
              <p className="text-lg font-bold text-green-600">{deal.currentQty}</p>
              <p className="text-xs text-gray-500">Total Units</p>
            </div>
          </div>

          {/* Progress */}
          <div>
            <div className="flex justify-between text-sm text-gray-600 mb-2">
              <span className="font-medium">Progress to target</span>
              <span className="font-bold">{deal.currentQty} / {deal.targetQty} ({progress.toFixed(0)}%)</span>
            </div>
            <div className="w-full bg-gray-100 rounded-full h-3">
              <div className={`h-3 rounded-full ${deal.status === 'completed' ? 'bg-green-500' : 'bg-primary'}`} style={{ width: `${Math.min(progress, 100)}%` }} />
            </div>
          </div>

          {/* Participants */}
          <div>
            <h3 className="font-semibold text-gray-900 mb-3">Participants</h3>
            <div className="space-y-2 max-h-48 overflow-y-auto">
              {deal.participants.length === 0 ? (
                <p className="text-sm text-gray-400 text-center py-4">No participants yet</p>
              ) : deal.participants.map(p => (
                <div key={p.id} className="flex items-center justify-between bg-gray-50 rounded-lg px-4 py-2.5">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center text-xs font-bold text-primary">
                      {p.shopName?.charAt(0) || '?'}
                    </div>
                    <span className="text-sm font-medium text-gray-700">{p.shopName}</span>
                  </div>
                  <span className="text-sm font-bold text-gray-900">{p.quantity} units</span>
                </div>
              ))}
            </div>
          </div>

          {/* Revenue estimate */}
          <div className="bg-green-50 border border-green-100 rounded-xl p-4">
            <div className="flex items-center gap-2 mb-1">
              <TrendingUp size={16} className="text-green-600" />
              <span className="text-sm font-bold text-green-700">Estimated Revenue</span>
            </div>
            <p className="text-2xl font-bold text-green-700">
              R{(deal.discountPrice * deal.currentQty).toFixed(2)}
            </p>
            <p className="text-xs text-green-600 mt-1">{deal.currentQty} units × R{deal.discountPrice.toFixed(2)} per unit</p>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t bg-gray-50 flex gap-3">
          <button onClick={onClose} className="flex-1 text-sm font-medium text-gray-700 bg-white border border-gray-200 py-2.5 rounded-xl hover:bg-gray-50 transition-colors">
            Close
          </button>
          {deal.status === 'active' && progress >= 100 && (
            <button onClick={onApprove} className="flex-1 text-sm font-medium text-white bg-green-600 hover:bg-green-700 py-2.5 rounded-xl transition-colors flex items-center justify-center gap-2">
              <CheckCircle size={16} /> Approve & Fulfill
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
