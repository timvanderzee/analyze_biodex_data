
if ishandle(100), close(100); end
figure(100)

id_SRS  = fdata(k).t > 0 & fdata(k).t < .04;

t = fdata(k).t(id_SRS) - fdata(k).t(find(id_SRS,1));
dA = fdata(k).angle(id_SRS) - fdata(k).angle(find(id_SRS,1));
dT = fdata(k).torque(id_SRS) - fdata(k).torque(find(id_SRS,1));
dw = fdata(k).acc(id_SRS) - fdata(k).acc(find(id_SRS,1));

subplot(311)
plot(t,dA)

subplot(312)
plot(t,dw)

subplot(313)
plot(t,dT)

% C = fminsearch(@(c) fcost(c,dA,dw,dT), [0 0]);
C = fmincon(@(c) fcost(c,dA,dw,dT), [0 0], [],[],[],[],[0 0], [], [], []);

hold on
plot(t, C(1)*dA,'--')