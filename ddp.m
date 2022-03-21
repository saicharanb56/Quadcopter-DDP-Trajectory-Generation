function [dus, V, Vn, dV, a] = ddp(x0, us, S)
% Second-order numerical optimal control. The code computes
% the optimal control adjustment for a given dynamical system
%
% params:
% x0 - initial state
% us - m-N matrix with discrete controls
% S - problem data:
%     S.L  : handle to the cost function
%     S.f  : handle to the discrete dynamics functions
%     S.mu : regularizing constant (default is 0)
%     S.a  : initial step size (default is 1)
%     S.diff : difference function (default is minus, i.e. vector space)
%
% return:
%   dus: m-N matrix containing computed optimal change in control
%   V: current value function
%   Vn: new value function
%   dV: predicted change in value function
%   a: computed step-size along control search direction
%
%
% Note: this implementation is most closely related to second-order 
% metehods known as stage-wise Newton (SN) - Bertsekas, 2003 
% and differential-dynamic-programming (DDP), Mayne, 1966. 
% In this implementation second-order terms in the dynamics 
% are ignored which corresponds to the linear-quadratic-subproblem
% (LQS) approach (see also iterative-LQR (Todorov et al)).
%
% Disclaimer: the code is for education purposes only
%
% Author: Marin Kobilarov marin(at)jhu.edu

if ~isfield(S, 'diff')
  S.diff = @diff_def;
end

if ~isfield(S, 'mu')
  S.mu = 0;
end

if ~isfield(S, 'mu0')
  S.mu0 = 1e-3;
end

if ~isfield(S, 'dmu0')
  S.dmu0 = 2;
end

if ~isfield(S, 'mumax')
  S.mumax = 1e6;
end

if ~isfield(S, 'a')
  S.a = 1;
end

if ~isfield(S, 'amin')
  S.amin = 1e-32;
end

if ~isfield(S, 'n')
  S.n = length(x0);
end

if ~isfield(S, 'info')
  S.info = 0;
end


n = S.n;
m = size(us, 1);

N = size(us, 2);

Ps = zeros(n,n,N+1);
vs = zeros(n,N+1);

cs = zeros(m,N);
Ds = zeros(m,n,N);

dus = zeros(size(us));

% integrate trajectory and get terminal cost
xs = ddp_traj(x0, us, S);
[L, Lx, Lxx, Lu, Luu] = S.L(N+1, xs(:,end), [], S);


% initialize
V = L;
v = Lx;
P = Lxx;

dV = [0; 0];

Ps(:,:,N+1) = P;
vs(:,N+1) = v;

for k=N:-1:1,
  
  x = xs(:,k);
  u = us(:,k);
  
  [xn, A, B] = S.f(k, x, u, S);
  
  if isempty(A) || isempty(B)
    [A, B] = fd(S.f, k, x, u, S, 1e-6);    
  end  
  
%   disp('The size of A is')
%   disp(size(A))
%   disp('The size of B is')
%   disp(size(B))  
  
  [L, Lx, Lxx, Lu, Luu] = S.L(k, x, u, S);
  
   
  %MODIFIED CODE TO DEFINE SOFTNESS OF CONSTRAINTS, BOUNDS, AND CONSTRAINTS
  beta = [0.8 0.8];
  %ub = [0.01; 0.01; 0.01; 0.01];
  %lb = [-0.05; -0.05; -0.05; -0.05];
  ub = 5*ones(4,1);
  lb = -5*ones(4,1);
  
  c1 = u - ub;
  c2 = lb - u;
  g1 = max(c1, 0);
  g2 = max(c2, 0);
  
  %MODIFIED COST FUNCTION TO ACCOUNT FOR CONSTRAINTS
  L = L + 0.5*beta*[norm(g1); norm(g2)].^2;
  Lu = Lu + [g1./(g1+0.00001) -g2./(g2+0.00001)].*[g1 g2]*beta';
  Luu = Luu + beta(1)*([(g1./(g1+0.00001))'; (-g2./(g2+0.00001))'])'*[(g1./(g1+0.00001))'; (-g2./(g2+0.00001))'] ...
        + beta(2)*([(g1./(g1+0.00001))'; (-g2./(g2+0.00001))'])'*[(g1./(g1+0.00001))'; (-g2./(g2+0.00001))'];
        
%   disp('The size of Lu is')
%   disp(size(Lu))
    
  V = V + L;
  
%   if u(1) > ub(1)
%     u(1) = ub(1);
%   end
%   
%   if u(2) > ub(2)
%     u(2) = ub(2);
%   end
%   
%   if u(1) < lb(1)
%     u(1) = lb(1);
%   end
%   
%   if u(2) < lb(2)
%     u(2) = lb(2);
%   end
  
  Qx = Lx + A'*v;
  Qu = Lu + B'*v;
  Qxx = Lxx + A'*P*A;
  Quu = Luu + B'*P*B;
  Qux = B'*P*A;
  
  mu = S.mu;
  dmu = 1;
  
  while 1
    Quum = Quu + mu*eye(m);
    
    [F, d] = chol(Quum);
    if d == 0
      % this is the standard quadratic rule specified by Tassa and Todorov
      dmu = min(1/S.dmu0, dmu/S.dmu0);
      if (mu*dmu > S.mu0)
        mu = mu*dmu;
      else
        mu = S.mu0;
      end
      
      if S.info
        disp(['[I] Ddp::Backward: reduced mu=' num2str(mu) ' at k=' num2str(k)]);          
      end
      break;      
    end

    dmu = max(S.dmu0, dmu*S.dmu0);
    mu = max(S.mu0, mu*dmu);
        
    if S.info
      disp(['[I] Ddp::Backward: increased mu=' num2str(mu) ' at k=' num2str(k)]);
    end
    
    if (mu > S.mumax)
      disp(S.mumax)
      disp(['[W] Ddp::Backward: mu= ' num2str(mu) 'exceeded maximum ']);
      break;
    end
    
  end
  
  if (mu > S.mumax)
    break;
  end
  
  % control law is du = c + D*dx
  cD = -F\(F'\[Qu, Qux]);
  c = cD(:, 1);
  D = cD(:, 2:end);
  
%   disp('The size of cD is')
%   disp(size(cD))
%   disp('The size of Qu is')
%   disp(size(Qu))
%   disp('The size of Qux is')
%   disp( size(Qux))
  
  v = Qx + D'*Qu;
  P = Qxx + D'*Qux;
  
  
  dV = dV + [c'*Qu; c'*Quu*c/2];
  
  vs(:, k) = v;
  Ps(:, :, k) = P;

  cs(:, k) = c; 
  Ds(:, :, k) = D; 

end

s1 = .1;
s2 = .5;
b1 = .25;
b2 = 2;

a = S.a;

% measured change in V
dVm = eps;

while dVm > 0

  % variation
  dx = zeros(n, 1);
  
  % varied x
  xn = x0;

  % new measured cost
  Vn = 0;
  
  for k=1:N,
    
    u = us(:,k);
    
    c = cs(:,k);
    D = Ds(:,:,k);

    du = a*c + D*dx;
    un = u + du;
    
    [Ln, Lx, Lxx, Lu, Luu] = S.L(k, xn, un, S);
    
    [xn, A, B] = S.f(k, xn, un, S);
    
    dx = S.diff(xs(:,k+1), xn);

    Vn = Vn + Ln;
    
    dus(:,k) = du;
  end
  
  [L, Lx, Lxx, Lu, Luu] = S.L(N+1, xn, [], S);
  Vn = Vn + L;
  
  dVm = Vn - V;
  
  if dVm > 0
    a = b1*a;
    if S.info
      disp(['[I] Ddp: decreasing a=' num2str(a)])
    end
    
    if a < S.amin
      break
    end

    continue    
  end
      
  dVp = [a; a*a]'*dV;
  
  r = dVm/dVp;
  
  if r < s1
    a = b1*a;
  else
    if r >= s2 
      a = b2*a;
    end
  end
  if S.info
    disp(['[I] ddp: decreasing a=' num2str(a)])
  end
  %disp(dVm)
end


function dx = diff_def(x, xn)
% default state difference 

dx = xn - x;


function [A, B] = fd(func, k, x, u, S, e)
% compute numerically the jacobians A=fx, B=fu of a given function f(k,x,u,S)

f = func(k, x, u, S);

n = length(x);
m = length(u);

En = eye(n);
Em = eye(m);

A = zeros(n, n);
B = zeros(n, m);

for j=1:n,
  A(:,j) = (func(k, x + e*En(:,j), u, S) - f)/e;
end

for j=1:m,
  B(:,j) = (func(k, x, u + e*Em(:,j), S) - f)/e;
end
