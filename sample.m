plot3(ans.xs(1,:),ans.xs(2,:),ans.xs(3,:), 'g', 'Linewidth',3);
axis equal
hold on

[X,Y,Z] = sphere;
surf(X-1.5,Y,Z+3)
surf(X-4,Y-4,Z+3.5)