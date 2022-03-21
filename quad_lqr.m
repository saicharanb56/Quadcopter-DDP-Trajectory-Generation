clc; clear;

syms x y z phi theta psi xDot yDot zDot p q r state A B u1 u2 u3 u4 real

g = 9.81;
Ix = 0.1;
Iy = 0.1;
Iz = 0.15;
m = 0.2;

state = [x y z phi theta psi xDot yDot zDot p q r]';

A = [xDot, yDot, zDot, ...
       p + q*cos(phi)*tan(theta) + r*cos(phi)*tan(theta), ...
       q*cos(phi) - r*sin(phi), ...
       q*sin(phi)/cos(psi) + r*cos(phi)/cos(psi), ...
       0, 0, g, ...
       (Iy - Iz)*q*r/Ix, (Iz - Ix)*p*r/Iy, (Ix - Iy)*p*q/Iz]';

B = sym(zeros(12,4));
B(7,1) = -(1/m)*(sin(phi)*sin(psi) + cos(phi)*cos(psi)*sin(theta));
B(8,1) = -(1/m)*(cos(psi)*sin(phi) - cos(phi)*sin(psi)*sin(theta));
B(9,1) = -(1/m)*(cos(phi)*cos(theta));

B(10,2) = 1/Ix;
B(11,3) = 1/Iy;
B(12,4) = 1/Iz;

%controls
u = [u1; u2; u3; u4];

%initial states and controls
state0 = zeros(length(state),1);
u0 = zeros(length(u),1);
u0(1) = 9.81;

%linearizing A
alpha = simplify(jacobian(A+B*u, state'));
func1 = matlabFunction(alpha);
linA = func1(state0(10),state0(6),state0(4),state0(11),state0(12),state0(5),u0(1));

%linearizing B
beta = simplify(jacobian(A+B*u,u'));
func2 = matlabFunction(beta);
linB = func2(state0(6),state0(4),state0(5));


