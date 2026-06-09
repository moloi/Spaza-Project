import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { ChevronRight, Shield } from 'lucide-react';
import AdminSidebar from './AdminSidebar';
import PageTransition from '../ui/PageTransition';
import GlobalSearch from '../ui/GlobalSearch';
import LiveClock from '../ui/LiveClock';
import NotificationBell from '../ui/NotificationBell';

const breadcrumbMap: Record<string, string> = {
  dashboard:     'Dashboard',
  suppliers:     'Suppliers',
  documents:     'Document Verification',
  products:      'Products',
  orders:        'Orders',
  analytics:     'Analytics',
  notifications: 'Notifications',
  settings:      'Settings',
};

export default function AdminLayout() {
  const navigate = useNavigate();
  const location = useLocation();
  const [collapsed, setCollapsed] = useState(false);

  const segments = location.pathname.split('/').filter(Boolean);
  const currentPage = breadcrumbMap[segments[1]] ?? 'Dashboard';

  return (
    <div className="flex min-h-screen bg-slate-50">
      <AdminSidebar collapsed={collapsed} onToggle={() => setCollapsed((c) => !c)} />

      <div className="flex-1 flex flex-col overflow-hidden min-w-0">
        {/* Header */}
        <header
          className="bg-white/90 backdrop-blur-md border-b border-gray-100 px-6 py-3 flex items-center justify-between flex-shrink-0 sticky top-0 z-30"
          style={{ boxShadow: '0 1px 0 rgba(0,0,0,0.04)' }}
        >
          <div className="flex items-center gap-2 text-sm">
            <div className="flex items-center gap-1.5 text-blue-600">
              <Shield size={14} />
              <span className="font-bold text-blue-700">Admin</span>
            </div>
            <ChevronRight size={14} className="text-gray-300" />
            <span className="font-bold text-gray-900">{currentPage}</span>
          </div>

          <div className="flex items-center gap-2">
            {/* Live Clock */}
            <LiveClock variant="admin" />

            {/* Search */}
            <GlobalSearch />

            {/* Notifications */}
            <NotificationBell variant="admin" />

            {/* Admin Avatar */}
            <div className="flex items-center gap-2.5 pl-3 border-l border-gray-100">
              <div className="w-7 h-7 rounded-full bg-gradient-to-br from-blue-600 to-blue-400 flex items-center justify-center text-white text-xs font-black">
                A
              </div>
              <div className="hidden sm:block">
                <p className="text-sm font-bold text-gray-900 leading-tight">Platform Admin</p>
                <p className="text-xs text-gray-400 leading-tight">admin@spazasure.co.za</p>
              </div>
            </div>
          </div>
        </header>

        <main className="flex-1 overflow-auto">
          <PageTransition>
            <Outlet />
          </PageTransition>
        </main>
      </div>
    </div>
  );
}
