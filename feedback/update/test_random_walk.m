close all
figure(1)
h = axes()

figure(1)
g = plot(h,1,1,'-')

set(h, 'xlim', [-10 10],'ylim', [-10 10])


set(g, 'Xdata', 3, 'Ydata', 1) 

% t = linspace(0,5,1000);
x = cumsum(.1*randn(1,1e6));
y = cumsum(.1*randn(1,1e6));

for i = 1:1e6
    
    N = 100;
    set(g, 'Xdata', x(i:N+i), 'Ydata', y(i:N+i)) 
    drawnow
    
    
end