function f = ddp_quad_obst_nl()

% time horizon and segments
tf = 30;
S.N = 300;
S.h = tf/S.N;

% cost function parameters
S.Q = 0.0*diag([20, 20, 2, ones(1,9)]);
S.R = 0.1*diag([10, 5, 5, 5]);
S.Qf = diag([2, 2, 2, ones(1,9)]);

S.f = @quad_f;
S.L = @quad_L;
S.Lf = @quad_Lf;
S.mu = 0;

% initial state
x0 = [-5; -5; 5; zeros(9,1)];

S.os(1).p = [-2;0;3];
S.os(1).r = 1;
S.os(2).p = [-4; -4; 3.5];
S.os(2).r = 1;
S.os(3).p = [-3.3; -2; 2];
S.os(3).r = 0.8;
S.ko = 1000;

% initial control sequence
%us = [repmat([.1;0.1], 1, S.N/2), repmat(-[.1;0.1], 1, S.N/2)]/5;
%us = [repmat([.1;0], 1, N/2), repmat(-[.1;0], 1, N/2)]/5;
us = zeros(4,S.N);

xs = ddp_traj(x0, us, S);

Jmin = ddp_cost(xs, us,  S);

%subplot(1,2,1)
plot3(xs(1,:), xs(2,:), xs(3,:), 'b')
hold on

if isfield(S, 'os')
%   da = .1;
%   a = -da:da:2*pi;
   [sphereX,sphereY,sphereZ] = sphere;
   for i=1:length(S.os)
%     % draw obstacle
%     plot(S.os(i).p(1) + cos(a)*S.os(i).r,  S.os(i).p(2) + sin(a)*S.os(i).r, ...
%          '-r','LineWidth',2);
%   end
%  axis equal
    
    surf(sphereX*S.os(i).r + S.os(i).p(1), sphereY*S.os(i).r + S.os(i).p(2), sphereZ*S.os(i).r + S.os(i).p(3))
    hold on
%     surf(sphereX*S.os(1).r + S.os(2).p(1), sphereY*S.os(2).r + S.os(2).p(2), sphereZ*S.os(2).r + S.os(2).p(3))
%     hold on
   end
end

S.a = 1;

for i=1:50
  [dus, V, Vn, dV, a] = ddp(x0, us, S);

  % update controls
  us = us + dus;
  
  S.a = a;   % reuse step-size for efficiency
  
  % update trajectory
  xs = ddp_traj(x0, us, S);

  plot3(xs(1,:), xs(2,:), xs(3,:), '-b');
end

plot3(xs(1,:), xs(2,:), xs(3,:), '-g', 'LineWidth', 3);
title('Trajectory from (-5,-5,5) to the origin');
axis equal
hold off

J = ddp_cost(xs, us, S);

xlabel('x')
ylabel('y')
zlabel('z')

subplot(1,2,2)
plot(0:S.h:tf-S.h, us(1,:));
hold on
plot(0:S.h:tf-S.h, us(2,:));
hold on
plot(0:S.h:tf-S.h, us(3,:));
hold on
plot(0:S.h:tf-S.h, us(4,:));
hold off
xlabel('Time in seconds')
ylabel('Control input')
title('Controls response')
legend('u_1','u_2', 'u_3','u_4')

f.xs = xs;
f.us = us;
end


function [L, Lx, Lxx, Lu, Luu] = quad_L(k, x, u, S)
% quad cost (just standard quadratic cost)

if (k == S.N+1)
  L = x'*S.Qf*x/2;
  Lx = S.Qf*x;
  Lxx = S.Qf;
  Lu = [];
  Luu = [];
else
  L = S.h/2*(x'*S.Q*x + u'*S.R*u);
  Lx = S.h*S.Q*x;
  Lxx = S.h*S.Q;
  Lu = S.h*S.R*u;
  Luu = S.h*S.R;
end

% quadratic penalty term
if isfield(S, 'os')
  for i=1:length(S.os)
    g = x(1:3) - S.os(i).p;
    c = S.os(i).r - norm(g);
    if c < 0
      continue
    end
    
    L = L + S.ko/2*c^2;
    v = g/norm(g);
    Lx(1:3) = Lx(1:3) - S.ko*c*v;
    Lxx(1:3,1:3) = Lxx(1:3,1:3) + S.ko*v*v';  % Gauss-Newton appox
  end
end

end

function xs = ddp_traj(x0, us, S)

N = size(us, 2);
xs(:,1) = x0;

for k=1:N,
  xs(:, k+1) = S.f(k, xs(:,k), us(:,k), S);
end
end

function [x, A, B] = quad_f(k, x, u, S)
% quad dynamics and jacobians

g = 9.81;
Ix = 0.1;
Iy = 0.1;
Iz = 0.15;
m = 0.2;

h = S.h;

xDot = x(7);
yDot = x(8);
zDot = x(9);
psi = x(4);
theta = x(5);
phi = x(6);
p = x(10);
q = x(11);
r = x(12);

% Nonlinear dynamics
% Af = [xDot, yDot, zDot, ...
%        q*sin(phi)/cos(theta) + r*cos(phi)/cos(theta), ...
%        q*cos(phi) - r*sin(phi), ...
%        p + q*sin(phi)*tan(theta) + r*cos(phi)*tan(theta), 0, 0, g, ...
%        (Iy - Iz)*q*r/Ix, (Iz - Ix)*p*r/Iy, (Ix - Iy)*p*q/Iz]';

% Nonlinear B
% Bg = zeros(12,4);
% Bg(7,1) = -(1/m)*(sin(phi)*sin(psi) + cos(phi)*cos(psi)*sin(theta));
% Bg(8,1) = -(1/m)*(cos(psi)*sin(phi) - cos(phi)*sin(psi)*sin(theta));
% Bg(9,1) = -(1/m)*(cos(phi)*cos(theta));
% 
% Bg(10,2) = 1/Ix;
% Bg(11,3) = 1/Iy;
% Bg(12,4) = 1/Iz;
% 
% Bg = h*Bg;

func1 = @(p,phi,psi,q,r,theta,u1)reshape([0.0,0.0,0.0,0.0,0.0,0.0,0.0, ...
          0.0,0.0,0.0,0.0,0.0,0.0,0.0, ...
          0.0,0.0,0.0,0.0,0.0,0.0,0.0, ...
          0.0,0.0,0.0,0.0,0.0,0.0,0.0,...
          0.0,0.0,0.0,0.0,0.0,0.0,0.0,...
          0.0,0.0,0.0,0.0,...
          1.0./cos(psi).^2.*sin(psi).*(r.*cos(phi)+q.*sin(phi)),...
          0.0,0.0,u1.*cos(psi).*sin(phi).*(-1.0./1.7e+1)+(u1.*cos(phi).*sin(psi).*sin(theta))./1.7e+1,...
          u1.*((sin(phi).*sin(psi))./1.7e+1+(cos(phi).*cos(psi).*sin(theta))./1.7e+1),...
          0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,...
          cos(phi).*1.0./cos(theta).^2.*(q+r),u1.*cos(phi).*cos(psi).*cos(theta).*(-1.0./1.7e+1),...
          (u1.*cos(phi).*cos(theta).*sin(psi))./1.7e+1,(u1.*cos(phi).*sin(theta))./1.7e+1,...
          0.0,0.0,0.0,0.0,0.0,0.0,(q.*cos(phi)-r.*sin(phi))./cos(psi),-r.*cos(phi)-q.*sin(phi),...
          -sin(phi).*tan(theta).*(q+r),u1.*cos(phi).*sin(psi).*(-1.0./1.7e+1)+(u1.*cos(psi).*sin(phi).*sin(theta))./1.7e+1,...
          -u1.*((cos(phi).*cos(psi))./1.7e+1+(sin(phi).*sin(psi).*sin(theta))./1.7e+1),(u1.*cos(theta).*sin(phi))./1.7e+1,...
          0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,...
          1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,r.*2.063997005988024e-1,q.*(-2.136671686746988e-1),0.0,0.0,0.0,sin(phi)./cos(psi),cos(phi),cos(phi).*tan(theta),0.0,0.0,0.0,r.*7.602755999049656e-3,0.0,p.*(-2.136671686746988e-1),0.0,0.0,0.0,cos(phi)./cos(psi),-sin(phi),cos(phi).*tan(theta),0.0,0.0,0.0,q.*7.602755999049656e-3,p.*2.063997005988024e-1,0.0],[12,12]);

func2 = @(phi,psi,theta)reshape([0.0,0.0,0.0,0.0,0.0,0.0,sin(phi).*sin(psi).*(-1.0./1.7e+1)-(cos(phi).*cos(psi).*sin(theta))./1.7e+1,cos(psi).*sin(phi).*(-1.0./1.7e+1)+(cos(phi).*sin(psi).*sin(theta))./1.7e+1,cos(phi).*cos(theta).*(-1.0./1.7e+1),0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,2.375861249703017e-1,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.25e+2./6.68e+2,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1.25e+2./6.64e+2],[12,4]);

A = func1(x(10),x(6),x(4),x(11),x(12),x(5),x(1));
A = h*A + eye(12);
B = func2(x(6),x(4),x(5));
B = h*B;

x = A*x + B*u;
end