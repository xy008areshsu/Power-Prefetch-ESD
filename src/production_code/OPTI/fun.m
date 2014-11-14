function [ y ] = fun( x )
%FUN Summary of this function goes here
%   Detailed explanation goes here

    y = 20 - x(1)^2 + x(2)^2 - 10*(cos(2*pi*x(1)) + cos(2*pi*x(2)));


end

