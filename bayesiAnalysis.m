clear
load('coal_mine.mat')

%% data visualization
% uncomment to visualize data:
x = linspace(1851, 1963, length(coal_mine));
histogram(coal_mine,30); 
title('British coal mine disasters')

%% defining parameters
hyperParam = 1;
breakpoints = 3; % change here the number of breakpoints
d = breakpoints+1;
ro = 0.05; % change here the value of rho
acc = zeros(1,breakpoints);

%% gibbs sampling with MH step

N = 10000;
burn_in = 5000;
M = N + burn_in;

% time intervals
t = zeros(d+1,M);
t(1,:) = 1851;
t(d+1,:) = 1963;

% first breakpoint
t(:,1) = linspace(1851, 1963, d+1);

% lambda intensities
lambda = zeros(d,M);

% theta parameter
theta = zeros(1,M);

% number of disasters
nDis = zeros(d,M);

% f(t)
ft = @(lambda,t,n) prod(lambda.^n .* exp(-lambda.*diff(t)) .* diff(t));

for j = 1:M-1
    
    theta(j) = gamrnd(2,1/hyperParam);
    
    % number of disaster update
    for i = 1:d
        nDis(i,j) = sum(coal_mine >= t(i,j) & coal_mine <= t(i+1,j));        
    end
    
    % lambda update
    lambda(:,j) = gamrnd(nDis(:,j)+2, 1./(diff(t(:,j))+theta(j)));
    
    % MH step
    for l = 2:d                
        cand = randWalkProp(ro, [t(l-1,j) t(l,j) t(l+1,j)]);
        t_star = t(:,j);
        t_star(l) = cand;
       
        if cand > t(l-1,j) && cand < t(l+1,j);
            for i = 1:d
                nDis_star(i,1) = sum(coal_mine >= t_star(i) & ...
                    coal_mine <= t_star(i+1));
            end
            alpha = ft(lambda(:,j), t_star, nDis_star) / ...
                    ft(lambda(:,j), t(:,j), nDis(:,j));
            if rand <= alpha
                t(l,j+1) = cand;
                acc(l-1) = acc(l-1) + 1;
            else
                t(l,j+1) = t(l,j);
            end            
        else
          t(l,j+1) = t(l,j);
        end
    end  
        
end 

acc = acc/M;
tau = ceil(mean(t(:, burn_in:M),2));

%% displaying lambda intensities

figure
s = size(lambda,1);
for i = 1:s
    subplot(s,1,i)
    h = histfit(lambda(i,:),50,'gamma');
    h(1).FaceColor = [.6 .8 1];
    str = sprintf('lambda %d', i);
    title(str) 
end    

%% displaying theta intensities
figure
h = histfit(theta,50,'gamma');
title('theta distribution')
h(1).FaceColor = [.6 .8 1];

%% displaying t samples
figure
for i = 2:size(t,1)-1
    %figure
    hold on
    plot(t(i,:))
    %str = sprintf('acceptance rate = %.3f, tau = %d', acc(i-1), tau(i));
    %title(str)
end

%%
figure
for i = 2:size(t,1)-1      
    hold on
    histogram(t(i,burn_in:end),20)
    str = sprintf('t distribution');
    title(str)
end
%% showing breakpoints

figure
hold on
histogram(coal_mine,30)
for i=2:size(t,1)-1
    SP = tau(i);
    line([SP SP], [0 15], 'Color', [1 0 0])
end
title('coal mine disasters')