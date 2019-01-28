% First, create a plane in matlab



%Decide on a suitable showing range
x=1:150;
z=1:150;

% Define the first plane
[X,Z] = meshgrid(x,z);
A = 0.75;
B = 2.5;
C = 3;
D = 4;
Y = (A * X + C * Z + D)/ (-B);


texture = imread('cameraman.tif');
texture = double(texture)/256;

h = surf(X, Y, Z, texture, 'Facecolor', 'texturemap', 'EdgeColor', 'none'), colormap(gray), hold on

A = -0.75;
B = 1.5;
C = 3;
D = 1;
Y = (A * X + C * Z + D)/ (-B);
surf(X, Y, Z, texture, 'Facecolor', 'texturemap', 'EdgeColor', 'none'), colormap(gray), 
% Define a second plane
