function [ch_out, ch_in, EEG_OUT_label, EEG_IN_label] = build_graph(val_group, delay_group, EEG_labels, ...
                         mic_group_median_pos_body, lag_group_median_pos_body, ...
                         mic_group_median_neg_body, lag_group_median_neg_body)


% take eeg -> body only 
val_out= val_group;
val_out(delay_group <= 0) = 0; 
delay_group(isnan(delay_group)) = 0;

% find max eeg channel 
[~, idx_out] = max(val_out(:));
[ch_out,~ ] = ind2sub(size(val_out), idx_out);
EEG_OUT_label = EEG_labels{ch_out};

%take body ->eeg only 
val_in = val_group;
val_in(delay_group >= 0) = 0;  

% find max eeg  
[~, idx_in] = max(val_in(:));
[ch_in, ~] = ind2sub(size(val_in), idx_in);
EEG_IN_label = EEG_labels{ch_in};

% nodi 
node_names = { ...
    ['EEG ' EEG_OUT_label], ...
    'CSI', ...
    'CVI', ...
    'EGG', ...
    ['EEG ' EEG_IN_label] ...
};

idx_EEG_OUT = find(strcmp(node_names, ['EEG ' EEG_OUT_label]));
idx_EEG_IN  = find(strcmp(node_names, ['EEG ' EEG_IN_label]));
idx_CSI     = find(strcmp(node_names,'CSI'));
idx_CVI     = find(strcmp(node_names,'CVI'));
idx_EGG     = find(strcmp(node_names,'EGG'));
idx_body    = 2:4;


% build edges

s = [];   % source (nodo di partenza)
t = [];   % target (nodo di arrivo)
w = [];   % weight 
lag = []; % delay

nt = 3;% n targhets 

% EEG → BODY (positive lag)

for tt = 1:nt
    mic_ = val_group(ch_out,tt);
    lag_ = delay_group(ch_out,tt);

    if mic_ > 0 && lag_ > 0
    
    s(end+1)   = idx_EEG_OUT;    % nodo 1 = EEG_OUT
    t(end+1)   = idx_body(tt);   % nodo 2,3,4 = CSI,CVI,EGG
    w(end+1)   = mic_;           %weight 
    lag(end+1) = round(lag_);
    
    end
end

% BODY → EEG (lag negativo)

for tt = 1:nt
    mic_ = val_group(ch_in,tt);
    lag_ = delay_group(ch_in,tt);

    if mic_ > 0 && lag_ < 0
    s(end+1)   = idx_body(tt);   % nodo CSI/CVI/EGG
    t(end+1)   = idx_EEG_IN;        % nodo EEG_IN
    w(end+1)   = mic_;
    lag(end+1) = round(lag_)
    end
end

% heart gut edges

% EGG → CSI
if mic_group_median_pos_body(1) > 0
    s(end+1)=idx_EGG; 
    t(end+1)=idx_CSI;
    w(end+1)=mic_group_median_pos_body(1);
    lag(end+1)=lag_group_median_pos_body(1);
end

% CSI → EGG
if mic_group_median_neg_body(1) > 0
    s(end+1)=idx_CSI;
    t(end+1)=idx_EGG;
    w(end+1)=mic_group_median_neg_body(1);
    lag(end+1)=lag_group_median_neg_body(1);
end

% EGG → CVI
if mic_group_median_pos_body(2) > 0
    s(end+1)=idx_EGG; 
    t(end+1)=idx_CVI;
    w(end+1)=mic_group_median_pos_body(2);
    lag(end+1)=lag_group_median_pos_body(2);
end

% CVI → EGG
if mic_group_median_neg_body(2) > 0
    s(end+1)=idx_CVI;
    t(end+1)=idx_EGG;
    w(end+1)=mic_group_median_neg_body(2);
    lag(end+1)=lag_group_median_neg_body(2);
end


% table
for i = 1:length(s)
    fprintf('%s →%s | mic =%.2f lag=%d\n', ...
        node_names{s(i)}, node_names{t(i)}, w(i), lag(i));
end

%%% create graph

G = digraph(s, t, w, node_names);
G.Edges.Lag = lag(:);


%%% position of nodes
X = [-0.3   2.3   2.3   3.2   -0.4];
Y = [ 1.1   1.0  -1.0   0.0   -1.1];

figure('Color','w')

p = plot(G,'XData',X,'YData',Y,'ArrowSize',14);
axis off
axis equal



%%%%% drawing part %%%%%%


% stile nodi e frecce 
p.NodeFontSize = 12;
p.MarkerSize   = 10;

if ~isempty(G.Edges.Weight)

    a=0.5 % modify a per spessore edges
    p.LineWidth = a +  2* G.Edges.Weight / max(G.Edges.Weight);
end

% rimuovo etichette automatiche 
xN = p.XData;
yN = p.YData;
p.NodeLabel = {};

% etichette archi (mic + lag) 

xN = p.XData;
yN = p.YData;





for e = 1:numedges(G)

    u = s(e);   % nodo source
    v = t(e);   % nodo traghet

    x1 = xN(u); y1 = yN(u); 
    x2 = xN(v); y2 = yN(v);

    dx = x2 - x1;
    dy = y2 - y1;

    L = hypot(dx,dy) + eps;

    % mettere label lungo l arco 
    alpha = 0.6;  % 0.5 = centro, >0.5 verso il target
    xm = x1 + alpha * dx;
    ym = y1 + alpha * dy;

    % perpendicolare all'arco
    nx = -dy / L;
    ny =  dx / L;

    % lato dipende dal segno del lag
    side = sign(lag(e));  
    if side == 0
        side = 1;
    end

    %  offset proporzionale alla lunghezza dell’arco
    offset = -0.05* L;

    xm = xm + side * offset * nx;
    ym = ym + side * offset * ny;

label = sprintf('MIC = %.2f | lag = %d', w(e), round(lag(e)));

h = text(xm, ym, label, ...
    'FontSize',10, ...
    'HorizontalAlignment','center', ...
    'BackgroundColor','w', ...
    'Margin',2);
end





%  etichette nodi manuali 
for i = 1:numel(G.Nodes.Name)

    dx = 0; dy = 0;

    if i==1 || i==numel(G.Nodes.Name), dx=-0.2; end
    if i==2, dy=0.15; 
    end
    if i==3, dy=-0.15; 
    end
    if i==4, dx=0.15; 
    end

    text(xN(i)+dx, yN(i)+dy, G.Nodes.Name{i}, ...
        'FontSize',14,'HorizontalAlignment','center');
end







%  rettangolo BRAIN 
pad1 = 0.5;
idx_brain = [1 numel(G.Nodes.Name)];

xmin = min(xN(idx_brain)) - pad1;
xmax = max(xN(idx_brain)) + pad1;
ymin = min(yN(idx_brain)) - pad1;
ymax = max(yN(idx_brain)) + pad1;

rectangle('Position',[xmin ymin xmax-xmin ymax-ymin], ...
    'Curvature',0.1,'LineWidth',1.2);

text(mean([xmin xmax]), ymax+0.18, 'Brain', ...
    'HorizontalAlignment','center', ...
    'FontWeight','bold', ...
    'FontSize', 16);


% rettangolo BODY
pad2=0.6
idx_body = 2:(numel(G.Nodes.Name)-1);

xmin = min(xN(idx_body)) - pad2;
xmax = max(xN(idx_body)) + pad2;
ymin = min(yN(idx_body)) - pad2;
ymax = max(yN(idx_body)) + pad2;

rectangle('Position',[xmin ymin xmax-xmin ymax-ymin], ...
    'Curvature',0.1,'LineWidth',1.2);

text(mean([xmin xmax]), ymax+0.18, 'Body', ...
    'HorizontalAlignment','center','FontWeight','bold','FontSize', 16);

% titolo 
title('Brain - Body Network, lagged MIC (α-band)', ...
    'FontWeight','bold','FontSize', 15)








end
