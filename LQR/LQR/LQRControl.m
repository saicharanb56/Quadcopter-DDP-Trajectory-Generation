%% Setup Drone
m = 0.2;
I = [[0.1,0,0];[0,0.1,0];[0,0,0.15]];

% sample time
ts = 0.01;

% Initial States
Euler_0 = [0;0;0];
XYZ_0 = [0;0;0];
body_rate_0 = [0;0;0]; % initial pqr

% Environment (North-East-Down coordinate)
g = [0;0;9.8];

%% Linear Model
% Option 1: Load default "Full States" Linear Model
load('LinearModel1');

% Option 2: Get Linear Model from Simulink model.
% model = 'DroneControl_Linear1';
% opspec = operspec(model);
% 
% % Specify operating states: Z position
% opspec = addoutputspec(opspec,'DroneControl_Linear1/6dof_system',3);
% opspec.Outputs(1).Known = true;
% opspec.Outputs(1).y = 0;
% 
% % Find Operating point
% op1 = findop(model,opspec);
% 
% % Get IO from simulink
% io = getlinio(model);
% % Set Inputs
% io(1) = linio('DroneControl_Linear1/Thrust',1,'input');
% io(2) = linio('DroneControl_Linear1/M_roll',1,'input');
% io(3) = linio('DroneControl_Linear1/M_pitch',1,'input');
% io(4) = linio('DroneControl_Linear1/M_yaw',1,'input');
% 
% io(5) = linio('DroneControl_Linear1/6dof_system',1,'output');
% io(6) = linio('DroneControl_Linear1/6dof_system',2,'output');
% io(7) = linio('DroneControl_Linear1/6dof_system',3,'output');
% io(8) = linio('DroneControl_Linear1/6dof_system',4,'output');
% io(9) = linio('DroneControl_Linear1/6dof_system',5,'output');
% io(10) = linio('DroneControl_Linear1/6dof_system',6,'output');
% io(11) = linio('DroneControl_Linear1/6dof_system',7,'output');
% io(12) = linio('DroneControl_Linear1/6dof_system',8,'output');
% io(13) = linio('DroneControl_Linear1/6dof_system',9,'output');
% io(14) = linio('DroneControl_Linear1/6dof_system',10,'output');
% io(15) = linio('DroneControl_Linear1/6dof_system',11,'output');
% io(16) = linio('DroneControl_Linear1/6dof_system',12,'output');
% 
% % Linearize
% sys = linearize(model,op1,io);


%% LQR regulator
% Set Q and R. Q: Performance Cost; R: Control Cost.

Q = sys.C'*sys.C;
R = eye(4);

%% Get K controller gain
K = lqr(sys.A,sys.B,Q,R);

%% Noise Charactersitic
% Process noise covariance
Qn = 1e-03*diag([0 0 0 0 0 0 1 1 1 1 1 1]);
% Measure noise covariance
Rn = 1e-04;

% Noise Level (0: no noise, 1: with noise)
NL = 0; %(default:0)

%% Simulation

% Task A or Task B (1: Task A, 2: Task B)
Task = 1;

if Task == 1    
    % Specify initial states (NED Coordinate)
    x0 = zeros(12,1);
    x0(4) = 1;    % Initial X position
    x0(5) = 1.5;    % Initial Y position
    x0(6) = 2;    % Initial Z position
     
    % simulation time
    stime = 8;
    % Run LQG.slx Simulink Model.
    out = sim('LQR',stime);

    t = out.t;
    u = out.u;
    y = out.y;
    viewlimit = 2;
    
else
    % pecify initial states (NED Coordinate)
    x0 = zeros(12,1);
    
    % simulation time
    stime = 30;
    
    % Load WayPts data
    load('WayPts_Test.mat');
    
    % Generate RefX,Y,Z signal
    XYZsignal;
    
    % Run LQG.slx Simulink Model.
    out = sim('LQR_Test',stime);

    t = out.t;
    u = out.u;
    y = out.y;
    viewlimit = 3.5;
end

%% 3D Animation

animation_LQR;

%% 2D Plot Performance, Control Effort

% Briefly estimate Battery power cost as inputs^2.
%Power = u(:,1).*u(:,1) + u(:,2).*u(:,2) + u(:,3).*u(:,3) + u(:,4).*u(:,4);
Power = 0*t;
for i = 1:length(t)
    if i == 1
        Power(i) = abs(y(i,7) - 0) + abs(y(i,8) - 0) + abs(y(i,9) - 0) + abs(y(i,10) - 0) + abs(y(i,11) - 0) + abs(y(i,12) - 0);
    else
        Power(i) = abs(y(i,7)-y(i-1,7)) + abs(y(i,8)-y(i-1,8)) + abs(y(i,9)-y(i-1,9)) + ...
                   abs(y(i,10)-y(i-1,10)) + abs(y(i,11)-y(i-1,11)) + abs(y(i,12)-y(i-1,12))  ;
    end
end


figure;
set(gcf,'position',[0,0,1200,600])
sub1=subplot(3,3,1);
axis([0 stime min(y(:,4)) max(y(:,4))]);
ylabel('X')
grid on
ani1=animatedline('Color','b','LineWidth',2);

subplot(3,3,4)
axis([0 stime min(y(:,5)) max(y(:,5))]); 
ylabel('Y')
grid on
ani2=animatedline('Color','g','LineWidth',2);

subplot(3,3,7)
axis([0 stime min(y(:,6)) max(y(:,6))]); 
ylabel('Z')
grid on
ani3=animatedline('Color','r','LineWidth',2);

subplot(3,3,3)
axis([0 stime min(u(:,1)) max(u(:,1))]); 
ylabel('Thrust (Perturbation)')
grid on
ani4=animatedline('Color','black','LineWidth',2);

subplot(3,3,2)
axis([0 stime min(u(:,2)) max(u(:,2))]); 
ylabel('M roll')
grid on
ani6=animatedline('Color','black','LineWidth',2);

subplot(3,3,5)
axis([0 stime min(u(:,3)) max(u(:,3))]); 
ylabel('M pitch')
grid on
ani7=animatedline('Color','black','LineWidth',2);

subplot(3,3,8)
axis([0 stime min(u(:,4)) max(u(:,4))]); 
ylabel('M yaw')
grid on
ani8=animatedline('Color','black','LineWidth',2);


subplot(3,3,6)
axis([0 stime min(Power) max(Power)]); 
ylabel('Power (Perturbation)')
grid on
ani5=animatedline('Color','black','LineWidth',2);

pause(1);

current_time = 0;
Energy = 0;
% text1 = annotation('textbox',[0.15 0.65 0.3 0.15],'String',{ 'Energy ',[' =' num2str(Energy)] } );
text(0, -0.5, 'Time:', 'FontSize', 14, 'HorizontalAlignment', 'left','Units','normalized');
TME = text(0.5, -0.5, num2str(current_time, '%.1f'), 'FontSize', 14, 'HorizontalAlignment', 'left','Units','normalized');
text(0, -1, 'Energy:', 'FontSize', 14, 'HorizontalAlignment', 'left','Units','normalized');
ENG = text(0.5, -1, num2str(Energy, '%.2f'), 'FontSize', 14, 'HorizontalAlignment', 'left','Units','normalized');

%%

for k=1:length(t)
    addpoints(ani1,t(k),y(k,4));    
    addpoints(ani2,t(k),y(k,5));
    addpoints(ani3,t(k),y(k,6));
    addpoints(ani4,t(k),u(k,1));
    addpoints(ani5,t(k),Power(k,1));
    addpoints(ani6,t(k),u(k,2));
    addpoints(ani7,t(k),u(k,3));
    addpoints(ani8,t(k),u(k,4));
    
    current_time = num2str(t(k), '%.1f');
    Energy = Energy + 100*abs(Power(k))*ts;
    TME.String = current_time;
    ENG.String = num2str(Energy, '%.1f');

    drawnow
    pause(0.01);
end











