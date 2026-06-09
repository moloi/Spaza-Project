import { useState } from 'react';
import { Outlet, useNavigate, useLocation } from 'react-router-dom';
import { ChevronRight } from 'lucide-react';
import Sidebar from './Sidebar';
import { useAuthStore } from '../../store/authStore';
import { Avatar } from '../ui';
import { resolveUploadUrl } from '../../services/api';
import PageTransition from '../ui/PageTransition';
import GlobalSearch from '../ui/GlobalSearch';
import LiveClock from '../ui/LiveClock';
import NotificationBell from '../ui/NotificationBell';

const breadcrumbMap: Record<string, string> = {
  dashboard: 'Dashboard',
  products: 'Products',
  orders: 'Orders',
  analytics: 'Analytics',
  notifications: 'Notifications',
  profile: 'Profile',
};

export default function AppLayout() {
  const { user } = useAuthStore();
  const navigate = useNavigate();
  const location = useLocation();
  const [collapsed, setCollapsed] = useState(false);
  const segments = location.pathname.split('/').filter(Boolean);
  const currentPage = breadcrumbMap[segments[0]] ?? 'Dashboard';

  return (
    <div className="flex min-h-screen bg-surface">
      <Sidebar collapsed={collapsed} onToggle={() => setCollapsed((c) => !c)} />

      <div className="flex-1 flex flex-col overflow-hidden min-w-0">
        {/* Top Header */}
        <header className="bg-white/90 backdrop-blur-md border-b border-gray-100 px-6 py-3 flex items-center justify-between flex-shrink-0 sticky top-0 z-30" style={{ boxShadow: '0 1px 0 rgba(0,0,0,0.04)' }}>
          {/* Breadcrumb */}
          <div className="flex items-center gap-2 text-sm">
            <span className="text-gray-400 font-medium">SpazaSure</span>
            <ChevronRight size={14} className="text-gray-300" />
            <span className="font-bold text-gray-900">{currentPage}</span>
          </div>

          <div className="flex items-center gap-2">
            {/* Live Clock */}
            <LiveClock variant="supplier" />

            {/* Search */}
            <GlobalSearch />

            {/* Notifications */}
            <NotificationBell variant="supplier" />

            {/* User */}
            <div
              className="flex items-center gap-2.5 pl-3 border-l border-gray-100 cursor-pointer hover:opacity-80 transition-opacity"
              onClick={() => navigate('/profile')}
            >
              <Avatar name={user?.companyName ?? 'S'} size="sm" src={user?.logoUrl ? resolveUploadUrl(user.logoUrl) : undefined} />
              <div className="hidden sm:block">
                <p className="text-sm font-bold text-gray-900 leading-tight">{user?.companyName}</p>
                <p className="text-xs text-gray-400 leading-tight">{user?.email}</p>
              </div>
            </div>
          </div>
        </header>

        {/* Main Content */}
        <main className="flex-1 overflow-auto">
          <PageTransition>
            <Outlet />
          </PageTransition>
        </main>
      </div>
    </div>
  );
}
