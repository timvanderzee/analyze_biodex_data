function[] = data_plot(data, id, color)

if nargin == 1
    id = 1:length(data.t);
    color = lines(1);
end

subplot(4,2,1)
plot(data.t(id), data.angle(id), 'color', color, 'linewidth', 1.5); hold on
title('Hoek')


subplot(4,2,2)
if isfield(data, 'FL')
    plot(data.t(id), data.FL(id), 'color', color, 'linewidth', 1.5); hold on
end
title('Fascicle lengte')

subplot(4,2,3)
plot(data.t(id), data.velocity(id), 'color', color, 'linewidth', 1.5); hold on
title('Hoeksnelheid')

subplot(4,2,4)
if isfield(data, 'acc')
plot(data.t(id), data.acc(id), 'color', color, 'linewidth', 1.5); hold on
title('Hoekversnelling')
end

subplot(4,2,5)
plot(data.t(id), data.torque(id), 'color', color, 'linewidth', 1.5); hold on
title('Moment')

muscles = {'TA', 'SOL', 'GAS'};
for k = 1:3
    subplot(4,2,k+5)
    plot(data.t(id), data.EMG(id,k), 'color', color, 'linewidth', 1.5); hold on
    title(muscles{k})
end

end