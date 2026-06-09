import { useState, useEffect } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import toast from 'react-hot-toast';
import { Eye, EyeOff, ArrowRight, Shield, Package, TrendingUp, ShieldCheck, Users, Star } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { Spinner } from '../../components/ui';
import { authApi } from '../../services/api';
import clsx from 'clsx';

const schema = z.object({
  email:    z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});
type FormData = z.infer<typeof schema>;

const stats = [
  { value: '1,000+', label: 'Spaza Shops' },
  { value: 'R5M+',   label: 'Monthly GMV'  },
  { value: '100+',   label: 'Suppliers'    },
  { value: '4.9★',   label: 'App Rating'   },
];
const features = [
  { icon: Package,     title: 'Product Catalog', desc: 'Manage products with bulk pricing'  },
  { icon: TrendingUp,  title: 'Live Analytics',  desc: 'Real-time revenue & order insights' },
  { icon: ShieldCheck, title: 'Compliance Hub',  desc: 'Document management & verification' },
  { icon: Users,       title: 'Shop Network',    desc: 'Connect with 1,000+ spaza shops'    },
];
const testimonial = {
  quote: 'SpazaSure transformed how we reach spaza shops. Orders up 340% in 3 months.',
  name:  'Thabo Nkosi',
  role:  'CEO, Fresh Foods SA',
  rating: 5,
};

/* Particles on the left dark panel */
const LEFT_PARTICLES = [
  { w: 3,  h: 3,  top: '12%', left: '15%', delay: '0s',    dur: '7s'  },
  { w: 2,  h: 2,  top: '35%', left: '8%',  delay: '1.2s',  dur: '9s'  },
  { w: 4,  h: 4,  top: '60%', left: '20%', delay: '2.5s',  dur: '6s'  },
  { w: 2,  h: 2,  top: '80%', left: '12%', delay: '0.7s',  dur: '11s' },
  { w: 3,  h: 3,  top: '22%', left: '88%', delay: '1.8s',  dur: '8s'  },
  { w: 2,  h: 2,  top: '70%', left: '82%', delay: '3.1s',  dur: '7.5s'},
  { w: 5,  h: 5,  top: '45%', left: '92%', delay: '0.4s',  dur: '10s' },
  { w: 2,  h: 2,  top: '88%', left: '75%', delay: '2s',    dur: '8.5s'},
];

/* Particles on the right light panel */
const RIGHT_PARTICLES = [
  { w: 4, h: 4, top: '14%', left: '7%',  delay: '0s',   dur: '6s'   },
  { w: 3, h: 3, top: '72%', left: '11%', delay: '1.5s', dur: '8s'   },
  { w: 5, h: 5, top: '28%', left: '87%', delay: '0.8s', dur: '7s'   },
  { w: 3, h: 3, top: '82%', left: '83%', delay: '2.2s', dur: '9s'   },
  { w: 4, h: 4, top: '50%', left: '4%',  delay: '3s',   dur: '6.5s' },
  { w: 2, h: 2, top: '18%', left: '76%', delay: '1s',   dur: '10s'  },
];

export default function LoginPage() {
  const [showPw,     setShowPw]     = useState(false);
  const [loading,    setLoading]    = useState(false);
  const [activeRole, setActiveRole] = useState<'supplier' | 'admin'>('supplier');
  const [ready,      setReady]      = useState(false);
  const { setUser } = useAuthStore();
  const navigate    = useNavigate();

  /* Single tick delay so CSS animations fire after first paint */
  useEffect(() => { const t = setTimeout(() => setReady(true), 30); return () => clearTimeout(t); }, []);

  const { register, handleSubmit, setValue, formState: { errors } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const switchRole = (role: 'supplier' | 'admin') => {
    setActiveRole(role);
    setValue('email', '');
    setValue('password', '');
  };

  const onSubmit = async (data: FormData) => {
    setLoading(true);
    try {
      const res = await authApi.login(data.email, data.password, activeRole);
      if (!res.success) { toast.error(res.message || 'Login failed'); return; }
      const { accessToken, refreshToken, expiresAt, role, userId } = res.data;
      const userRole: 'supplier' | 'admin' = role === 'admin' ? 'admin' : 'supplier';

      // Enforce role match: prevent suppliers from logging in on Admin tab and vice versa
      if (userRole !== activeRole) {
        toast.error(
          activeRole === 'admin'
            ? 'This account is not an admin. Please use the Supplier Login tab.'
            : 'This account is an admin. Please use the Admin Login tab.'
        );
        return;
      }

      setUser({
        id: String(userId),
        email: data.email,
        companyName: '',
        role: userRole,
        tier: 'basic',
        isVerified: false,
        token: accessToken,
        refreshToken,
        tokenExpiresAt: typeof expiresAt === 'string' ? expiresAt : new Date(expiresAt).toISOString(),
      });
      toast.success('Welcome back!');
      setTimeout(() => navigate(userRole === 'admin' ? '/admin/dashboard' : '/dashboard'), 50);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg || 'Invalid credentials. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  /* Helper — apply animation only after ready, with a fill-mode so it stays visible */
  const anim = (name: string, delay = '0ms', duration = '700ms') =>
    ready
      ? { animation: `${name} ${duration} cubic-bezier(0.16,1,0.3,1) ${delay} both` }
      : { opacity: 0 };

  return (
    <div className="h-screen w-screen flex overflow-hidden bg-[#0A1A0F]">

      {/* ═══════════════════════════════════════════════════════════
          LEFT PANEL
          ═══════════════════════════════════════════════════════════ */}
      <div className="hidden lg:flex lg:w-[52%] relative flex-col overflow-hidden">

        {/* ── Animated background gradient */}
        <div
          className="absolute inset-0"
          style={{
            background: 'linear-gradient(135deg,#071109,#1B4332,#0D2E1A,#2E7D52,#071109)',
            backgroundSize: '400% 400%',
            animation: 'gradientShift 12s ease infinite',
          }}
        />

        {/* ── Drifting orbs */}
        <div className="absolute top-[-60px] left-[-40px] w-80 h-80 rounded-full bg-[#4CAF50]/12 blur-[70px] animate-orb-drift-1" />
        <div className="absolute bottom-[-50px] right-[-30px] w-72 h-72 rounded-full bg-[#F59E0B]/10 blur-[65px] animate-orb-drift-2" />
        <div className="absolute top-[40%] left-[40%] w-56 h-56 rounded-full bg-[#2E7D52]/18 blur-[50px] animate-orb-drift-3" />

        {/* ── Grid */}
        <div className="absolute inset-0 opacity-[0.03]"
          style={{ backgroundImage: 'linear-gradient(rgba(255,255,255,0.7) 1px,transparent 1px),linear-gradient(90deg,rgba(255,255,255,0.7) 1px,transparent 1px)', backgroundSize: '44px 44px' }} />

        {/* ── Floating particles */}
        {LEFT_PARTICLES.map((p, i) => (
          <div key={i} className="absolute rounded-full bg-[#4CAF50]/30 animate-particle-float pointer-events-none"
            style={{ width: p.w, height: p.h, top: p.top, left: p.left, animationDelay: p.delay, animationDuration: p.dur }} />
        ))}

        {/* ── Content */}
        <div className="relative z-10 flex flex-col justify-between h-full px-10 py-7">

          {/* ① LOGO */}
          <div style={anim('slideLeft', '0ms', '800ms')} className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl overflow-hidden ring-2 ring-white/25 shadow-xl flex-shrink-0"
              style={{ boxShadow: '0 0 20px rgba(76,175,80,0.3), 0 4px 16px rgba(0,0,0,0.4)' }}>
              <img src="/spazasure_logo.jpg" alt="SpazaSure" className="w-full h-full object-cover" />
            </div>
            <div>
              <h1 className="text-base font-black text-white tracking-tight leading-none">SpazaSure</h1>
              <p className="text-[9px] font-bold tracking-[0.22em] uppercase text-[#4CAF50] mt-0.5">Supplier Portal</p>
            </div>
          </div>

          {/* ② HEADLINE */}
          <div style={anim('slideLeft', '120ms', '800ms')}>
            {/* Badge with pulse ring */}
            <div className="inline-flex items-center gap-2 bg-[#4CAF50]/15 border border-[#4CAF50]/30 rounded-full px-3 py-1 mb-3 animate-badge-pulse">
              <span className="w-1.5 h-1.5 rounded-full bg-[#4CAF50] animate-glow-pulse flex-shrink-0" />
              <span className="text-[9px] font-bold text-[#4CAF50] tracking-widest uppercase">South Africa's #1 B2B Platform</span>
            </div>
            <h2 className="text-[2.1rem] font-black text-white leading-[1.1] tracking-tight mb-2">
              Grow your<br />
              <span
                className="text-transparent bg-clip-text"
                style={{ backgroundImage: 'linear-gradient(90deg,#4CAF50,#81C784,#4CAF50)', backgroundSize: '200% auto', animation: 'btnShimmer 3s linear infinite' }}
              >
                spaza business
              </span><br />
              with confidence
            </h2>
            <p className="text-[#A7C4B0] text-xs leading-relaxed max-w-xs">
              Connect with thousands of verified spaza shops. Manage orders, track payments, grow revenue — all in one place.
            </p>
          </div>

          {/* ③ FEATURE CARDS */}
          <div className="grid grid-cols-2 gap-2">
            {features.map(({ icon: Icon, title, desc }, i) => (
              <div
                key={title}
                style={anim('popIn', `${240 + i * 80}ms`, '600ms')}
                className="group bg-white/[0.04] hover:bg-white/[0.09] border border-white/[0.07] hover:border-[#4CAF50]/40 rounded-xl p-3 cursor-default transition-all duration-300 hover:-translate-y-0.5"
              >
                <div className="w-6 h-6 bg-[#4CAF50]/15 rounded-lg flex items-center justify-center mb-1.5 group-hover:bg-[#4CAF50]/30 group-hover:scale-110 group-hover:rotate-3 transition-all duration-300">
                  <Icon size={12} className="text-[#4CAF50]" />
                </div>
                <p className="text-white text-[11px] font-bold leading-none mb-0.5">{title}</p>
                <p className="text-[#7A9E8A] text-[10px] leading-snug">{desc}</p>
              </div>
            ))}
          </div>

          {/* ④ STATS */}
          <div style={anim('slideLeft', '560ms', '700ms')}
            className="bg-white/[0.04] border border-white/[0.07] rounded-xl px-4 py-2.5">
            <div className="grid grid-cols-4 divide-x divide-white/[0.07]">
              {stats.map(({ value, label }, i) => (
                <div key={label} className="text-center px-2" style={anim('counterUp', `${640 + i * 60}ms`, '600ms')}>
                  <p className="text-sm font-black text-white tabular-nums">{value}</p>
                  <p className="text-[9px] font-semibold text-[#7A9E8A] mt-0.5">{label}</p>
                </div>
              ))}
            </div>
          </div>

          {/* ⑤ TESTIMONIAL */}
          <div style={anim('slideLeft', '700ms', '800ms')}
            className="bg-gradient-to-br from-[#1B4332]/80 to-[#0D2E1A]/80 border border-[#4CAF50]/20 rounded-xl p-3.5">
            <div className="flex gap-0.5 mb-1.5">
              {Array.from({ length: testimonial.rating }).map((_, i) => (
                <Star key={i} size={10} className="fill-[#F59E0B] text-[#F59E0B]"
                  style={{ animation: `popIn 0.4s cubic-bezier(0.34,1.56,0.64,1) ${300 + i * 60}ms both` }} />
              ))}
            </div>
            <p className="text-[#C8DDD0] text-[11px] leading-relaxed italic mb-2.5">"{testimonial.quote}"</p>
            <div className="flex items-center gap-2">
              <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#4CAF50] to-[#2E7D52] flex items-center justify-center text-white text-[9px] font-black flex-shrink-0"
                style={{ boxShadow: '0 0 8px rgba(76,175,80,0.5)' }}>
                {testimonial.name.charAt(0)}
              </div>
              <div>
                <p className="text-white text-[10px] font-bold leading-none">{testimonial.name}</p>
                <p className="text-[#7A9E8A] text-[9px] mt-0.5">{testimonial.role}</p>
              </div>
            </div>
          </div>

        </div>
      </div>

      {/* ═══════════════════════════════════════════════════════════
          RIGHT PANEL
          ═══════════════════════════════════════════════════════════ */}
      <div className="flex-1 flex items-center justify-center px-6 lg:px-10 bg-[#F4F7F5] relative overflow-hidden">

        {/* Orbs */}
        <div className="absolute top-0 right-0 w-64 h-64 bg-[#4CAF50]/7 rounded-full blur-[70px] pointer-events-none animate-orb-drift-2" />
        <div className="absolute bottom-0 left-0 w-52 h-52 bg-[#1B4332]/6 rounded-full blur-[55px] pointer-events-none animate-orb-drift-1" />

        {/* Floating particles */}
        {RIGHT_PARTICLES.map((p, i) => (
          <div key={i} className="absolute rounded-full bg-[#4CAF50]/25 animate-particle-float pointer-events-none"
            style={{ width: p.w, height: p.h, top: p.top, left: p.left, animationDelay: p.delay, animationDuration: p.dur }} />
        ))}

        <div className="w-full max-w-[390px] relative z-10">

          {/* Mobile logo */}
          <div style={anim('slideDown', '0ms')} className="lg:hidden flex items-center gap-3 mb-5">
            <div className="w-9 h-9 rounded-xl overflow-hidden ring-2 ring-[#1B4332]/20 shadow-md flex-shrink-0">
              <img src="/spazasure_logo.jpg" alt="SpazaSure" className="w-full h-full object-cover" />
            </div>
            <div>
              <h1 className="text-base font-black text-[#1B4332] leading-none">SpazaSure</h1>
              <p className="text-[9px] font-bold tracking-widest uppercase text-[#4CAF50]">Supplier Portal</p>
            </div>
          </div>

          {/* Role toggle */}
          <div style={anim('slideDown', '80ms')}
            className="flex gap-1 bg-white border border-gray-200 rounded-2xl p-1.5 mb-3 shadow-sm">
            {(['supplier', 'admin'] as const).map((role) => (
              <button
                key={role}
                onClick={() => switchRole(role)}
                className={clsx(
                  'flex-1 flex items-center justify-center gap-1.5 py-2 rounded-xl text-xs font-bold transition-all duration-300',
                  activeRole === role
                    ? role === 'supplier'
                      ? 'bg-gradient-to-r from-[#1B4332] to-[#2E7D52] text-white shadow-md scale-[1.02]'
                      : 'bg-gradient-to-r from-[#0F172A] to-[#1E293B] text-white shadow-md scale-[1.02]'
                    : 'text-gray-400 hover:text-gray-700 hover:bg-gray-50'
                )}
              >
                {role === 'supplier' ? <Package size={12} /> : <Shield size={12} />}
                {role === 'supplier' ? 'Supplier Login' : 'Admin Login'}
              </button>
            ))}
          </div>

          {/* ── MAIN CARD with glowing border animation */}
          <div
            style={anim('popIn', '160ms', '600ms')}
            className="bg-white rounded-3xl border border-gray-100/80 px-7 py-6 animate-card-glow"
          >

            {/* Card header */}
            <div style={anim('slideRight', '260ms')} className="mb-5">
              <div className={clsx(
                'inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[10px] font-bold tracking-wide uppercase mb-2.5 transition-all duration-300',
                activeRole === 'supplier' ? 'bg-[#E8F5E9] text-[#1B4332]' : 'bg-slate-100 text-slate-700'
              )}>
                {activeRole === 'supplier' ? <Package size={9} /> : <Shield size={9} />}
                {activeRole === 'supplier' ? 'Supplier Login' : 'Admin Login'}
              </div>
              <h2 className="text-xl font-black text-gray-900 tracking-tight leading-tight">
                {activeRole === 'admin' ? 'Welcome back, Admin' : 'Welcome back'}
              </h2>
              <p className="text-gray-400 text-xs mt-1 font-medium">
                {activeRole === 'admin' ? 'Sign in to manage the SpazaSure platform' : 'Sign in to your supplier account'}
              </p>
            </div>

            <form onSubmit={handleSubmit(onSubmit)} className="space-y-3.5">

              {/* Email */}
              <div style={anim('slideRight', '340ms')}>
                <label className="block text-[10px] font-bold text-gray-500 mb-1 uppercase tracking-wider">
                  Email Address
                </label>
                <input
                  {...register('email')}
                  type="email"
                  autoComplete="email"
                  placeholder="you@company.co.za"
                  className={clsx(
                    'w-full border rounded-xl px-3.5 py-2.5 text-sm bg-gray-50 text-gray-900 font-medium',
                    'focus:outline-none focus:ring-2 focus:bg-white transition-all duration-200 placeholder:text-gray-300',
                    errors.email
                      ? 'border-red-300 focus:ring-red-200 focus:border-red-400'
                      : 'border-gray-200 focus:ring-[#1B4332]/20 focus:border-[#1B4332]'
                  )}
                />
                {errors.email && (
                  <p className="text-red-500 text-[10px] mt-1 font-semibold flex items-center gap-1">
                    <span className="w-1 h-1 rounded-full bg-red-500 inline-block flex-shrink-0" />
                    {errors.email.message}
                  </p>
                )}
              </div>

              {/* Password */}
              <div style={anim('slideRight', '420ms')}>
                <div className="flex items-center justify-between mb-1">
                  <label className="block text-[10px] font-bold text-gray-500 uppercase tracking-wider">Password</label>
                  <Link to="/forgot-password" className="text-[10px] font-bold text-[#1B4332] hover:text-[#4CAF50] transition-colors">
                    Forgot password?
                  </Link>
                </div>
                <div className="relative">
                  <input
                    {...register('password')}
                    type={showPw ? 'text' : 'password'}
                    autoComplete="current-password"
                    placeholder="••••••••"
                    className={clsx(
                      'w-full border rounded-xl px-3.5 py-2.5 pr-10 text-sm bg-gray-50 text-gray-900 font-medium',
                      'focus:outline-none focus:ring-2 focus:bg-white transition-all duration-200 placeholder:text-gray-300',
                      errors.password
                        ? 'border-red-300 focus:ring-red-200 focus:border-red-400'
                        : 'border-gray-200 focus:ring-[#1B4332]/20 focus:border-[#1B4332]'
                    )}
                  />
                  <button type="button" onClick={() => setShowPw(!showPw)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-300 hover:text-gray-600 transition-all duration-200 hover:scale-110">
                    {showPw ? <EyeOff size={14} /> : <Eye size={14} />}
                  </button>
                </div>
                {errors.password && (
                  <p className="text-red-500 text-[10px] mt-1 font-semibold flex items-center gap-1">
                    <span className="w-1 h-1 rounded-full bg-red-500 inline-block flex-shrink-0" />
                    {errors.password.message}
                  </p>
                )}
              </div>

              {/* Submit — shimmer sweep button */}
              <div style={anim('slideRight', '500ms')}>
                <button
                  type="submit"
                  disabled={loading}
                  className={clsx(
                    'relative w-full flex items-center justify-center gap-2 py-3 rounded-xl font-bold text-sm text-white overflow-hidden',
                    'shadow-lg hover:shadow-xl hover:-translate-y-0.5 active:scale-[0.98] active:translate-y-0',
                    'transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-offset-2',
                    'disabled:opacity-60 disabled:cursor-not-allowed disabled:hover:translate-y-0',
                    activeRole === 'admin'
                      ? 'bg-gradient-to-r from-[#0F172A] to-[#1E293B] hover:from-[#1E293B] hover:to-[#334155] shadow-slate-900/25 focus:ring-slate-700'
                      : 'bg-gradient-to-r from-[#1B4332] to-[#2E7D52] hover:from-[#143326] hover:to-[#1B4332] shadow-[#1B4332]/30 focus:ring-[#1B4332]'
                  )}
                >
                  {/* Shimmer sweep overlay */}
                  {!loading && (
                    <span
                      className="absolute inset-0 pointer-events-none"
                      style={{
                        background: 'linear-gradient(105deg, transparent 40%, rgba(255,255,255,0.18) 50%, transparent 60%)',
                        backgroundSize: '200% auto',
                        animation: 'btnShimmer 2.5s linear infinite',
                      }}
                    />
                  )}
                  <span className="relative flex items-center gap-2">
                    {loading ? <><Spinner size="sm" /> Signing in...</> : <>Sign In <ArrowRight size={14} /></>}
                  </span>
                </button>
              </div>
            </form>

            {/* Register link */}
            {activeRole === 'supplier' && (
              <div style={anim('fadeIn', '600ms')} className="mt-4 pt-4 border-t border-gray-100">
                <p className="text-center text-xs text-gray-400 font-medium">
                  Don't have an account?{' '}
                  <Link to="/register" className="text-[#1B4332] font-bold hover:text-[#4CAF50] transition-colors">
                    Register as Supplier →
                  </Link>
                </p>
              </div>
            )}
          </div>

          {/* Trust badges */}
          <div style={anim('slideDown', '680ms')} className="flex items-center justify-center gap-5 mt-3">
            {[
              { icon: '🔒', text: 'SSL Secured'     },
              { icon: '🇿🇦', text: 'POPIA Compliant' },
              { icon: '✓',  text: 'CIPC Verified'   },
            ].map(({ icon, text }, i) => (
              <div key={text} className="flex items-center gap-1 text-gray-400 hover:text-gray-600 transition-colors cursor-default"
                style={anim('popIn', `${720 + i * 60}ms`, '400ms')}>
                <span className="text-[10px]">{icon}</span>
                <span className="text-[9px] font-semibold">{text}</span>
              </div>
            ))}
          </div>

        </div>
      </div>
    </div>
  );
}
