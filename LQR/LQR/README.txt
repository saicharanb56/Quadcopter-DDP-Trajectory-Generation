Chun-Wei, Kong 2021.03.17

There are 2 main tasks in this file.
First, user can design a LQR regulator controller or LQG controller based on the linear quadcopter model.
Then, user can implement these controllers to the actual non-linear quadcopter model to see the response.

Workflow:
[linear model] ----> Task A: Design LQR Controller/ LQG Controller ----> Task B: Implement & Validate on non-linear model

A Task: Design LQR Regulator controller and Kalman Filter by linear quadcopter model.
    LQG: Kalman Filter + LQR Regulator
    LQG reference: https://www.mathworks.com/help/control/getstart/linear-quadratic-gaussian-lqg-design.html
    Kalman Filter reference: https://www.mathworks.com/help/ident/ref/kalmanfilter.html

B Task: Implement the LQR Regulator and Kalam Filter on non-linear quadcopter model.

============================================================================================
A Task.

Design LQR Controller
Files?
	LQRControl.m
	DroneControl_Linear1.slx (For LQRControl.m script to linearize, full-state model)
	LQR.slx	
	animation_LQR.m

How to Run it?
	Run each section of the LQRControl.m

Function in each file?
1. LQRContro.m
	- Set LQR Reuglator's Weight Matrix for Performance and Control effort by Q and R
        Q[4,4] : X tracking ability
        Q[5,5] : Y tracking ability
        Q[6,6] : Z tracking ability
        R[1,1] : Thrust cost effort
        R[2,2] : ToruqeX cost effort
        R[3,3] : ToruqeY cost effort
        R[4,4] : TorqueZ cost effort
	- Set Initial Position of the Simulation : x0
    - NL: Set noise level (default: 0)

2. animation_LQR.m
	- Set animation boundaries and window size. 
------------------------------------------------------------------------------------------------------

Design LQG Controller:
Files?
        LQGControl.m
        DroneControl_Linear2.slx (For LQGControl.m script to linearize, can't measure full-state)
        LQG.slx
        animation_LQG.m

How to Run it?
        Run each section of the LQGControl.m

Function in each file?
1. LQGContro.m
        - Set LQR Reuglator's Weight Matrix for Performance and Control effor by Q and R
            (Same as LQRControl.m)
        - Set Initial Position of the Simulation
        - NL: Set noise level (default: 1)
          
2. LQG.slx
        * Set Noise Characteristics in Kalman Filter block

3. animation_LQG.m
        - Set animation boundaries and window size.

------------------------------------------------------------------------------------------------------------
Although I add the noise term in the LQR.slx model.
I think it is not reasonable to compare the result of LQR and LQG, becasue of one important reason.

To use the LQR, we "assume" that we are able to measure "all states" of the model.
Thus, we can feedback the full-states to the LQR regulator and generate the control inputs.
However, for the LQG, we "assume" that we are not able to measure all of the state of the model,
which is also the usual case in real world situation.
Thus, we need to use a Kalman filter to "estimate" the states we want.
Then feedback these "estimating states" to the LQR regulator and generate the control inputs.

In conclusion, they are based on different degree of "simulation reality".
LQR is used on a "perfect" situation.
LQG is used on a "real world" situation.
It might not be a good choise to directly compare the result of them.
On the other hand, a better way to think of the relation of LQR and LQG is:
First, we have a perfect model and we use LQR regulator to control it.
Then, we want to introduce the "real-world effects", such as noises and measurement ability to make
the model more realisitc. 
In order to do so, we need to add a Kalman filter before the LQR regulator.

From the 3D animation, you would find
LQR is too perfect to be true.
LQG is more similar to what happens in real world.

====================================================================================================================
B Task

Implement LQR Controller
Files?
    LQRConotrol.m
    LQR_Test.slx
    WayPts_Test.mat
    XYZsignal.m

How to run it?
    1. Change the Task parameter to 2 in the %% Simulation section of the LQRControl.m script.
    2. Run each section of the LQRControl.m script
        

Functions in each file?
    LQRControl.m
        - User can change the LQR regulator controller gain K by changing the Q and R Matrix and run the %% Get K Controller gain section
    LQR_Test.slx
        - User can switch between two types of RefX, RefY, RefZ signal. (1. simple step input, or 2. complex waypoints inputs)
    WayPts_Test.mal
        - User can specify the WayPoints of the drone by this matrix [x,y,z,t]

---------------------------------------------------------------------------------------------------------------------------

Implement LQG Controller
Files?
    LQRConotrol.m
    LQR_Test.slx
    WayPts_Test.mat
    XYZsignal.m

How to run it?
    1. Change the Task parameter to 2 in the %% Simulation section of the LQGControl.m script.
    2. Run each section of the LQRControl.m script
        
Functions in each file?
    LQRControl.m
        - User can change the LQR regulator controller gain K by changing the Q and R Matrix and run the %% Get K Controller gain section
        - User can turn on/off the noise by setting NL = 0;
    LQR_Test.slx
        - User can switch between two types of RefX, RefY, RefZ signal. (1. waypoints inputs (default) or 2. simple step input)
    WayPts_Test.mal
        - User can specify the WayPoints of the drone by this matrix [x,y,z,t]

-------------------------------------------------------------------------------------------------------------------------------
LQR or LQG is a linear controller design method.
It can be used also on non-linear model by first linearize it.
After the design, we need to implement it on the original non-linear model to validate it.
The advantage of this linear controller is that we can quickly and easily analyze its performance and control effort cost.
The problem is that sometimes it might not be able to implement on the non-linear model.


   

