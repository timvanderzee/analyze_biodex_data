function[] = data_plot(data, id, color)

subplot(3,2,1)
plot(data.t(id), data.angle(id), 'color', color); hold on

subplot(3,2,2)
plot(data.t(id), data.velocity(id), 'color', color); hold on

subplot(3,2,3)
plot(data.t(id), data.torque(id), 'color', color); hold on

for k = 1:3
subplot(3,2,k+3)
plot(data.t(id), data.EMG(id,k), 'color', color); hold on
% title(num2str(k))
end

end