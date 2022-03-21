syms x y z psi theta phi xDot yDot zDot p q r state A B u1 u2 u3 u4

S

function g = linearizedA(S, I)

    %[x, y, z, psi, theta, phi, xDot, yDot, zDot, p, q, r] = S.state;

    F = [S.state(7), S.state(8), S.state(9), ...
       S.state(11)*sin(S.state(6))/cos(S.state(4)) + S.state(12)*cos(S.state(6))/cos(S.state(4)), ...
       S.state(11)*cos(S.state(6)) - S.state(12)*sin(S.state(6)), ...
       S.state(10) + S.state(11)*cos(S.state(6))*tan(S.state(5)) + S.state(12)*cos(S.state(6))*tan(S.state(5)), ...
       0, 0, g, ...
       (I(2) - I(3))*S.state(11)*S.state(12)/I(1), (I(3) - I(1))*S.state(10)*S.state(12)/I(2), (I(1) - I(2))*S.state(10)*S.state(11)/I(3)]';

    A = jacobian(F,S.state');
    
    func = matlabFunction(A);
    g = func(0,0,0,0,0,0,0);
end