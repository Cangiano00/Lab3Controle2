%
% Identificacao Open Loop
% Funcao de transferencia de velocidade
%
function [vetorrk,vetoryk,T] = IdentificacaoOpenLoopV1()
clear all;               % remove o workspace anterior
delete(timerfindall);    % deleta todos os timers anteriormente alocados
%
% parametros do tempo
% 
Fa = 20;         % Sampling frequency
T = 1/Fa;        % Sampling time
Duration = 20;   % Duracao em segundos
%%%%%
NumberOfTasksToExecute = round(Duration/T);  % <---- Numero de vezes que o controlador e' executado
%%%%%
%
% Criacao de uma onda quadrada nao simetrica de referencia com periodo Per
% Amplitude +A -> Amplitude varia de 0 Volts ate +A Volts
A   = 3.5;
Per = 10;
referencia = zeros(NumberOfTasksToExecute+1,1);
t = linspace(0,Duration,NumberOfTasksToExecute+1);
referencia = A*square(2*pi*(1/Per)*t);

% Create and configure timer object
tm = timer('ExecutionMode','fixedRate', ...            % Run continuously
    'Period',T, ...                                    % Period = sampling time
    'TasksToExecute',NumberOfTasksToExecute, ...       % Runs NumberOfTasksToExecute times
    'TimerFcn',@MyTimerFcn, ...                        % Run MyTimerFcn at each timer event
    'StopFcn',@StopEverything);
% setup da placa
s = daq.createSession('ni');
addAnalogInputChannel(s,'Dev1',0:1,'Voltage');
addAnalogOutputChannel(s,'Dev1',0,'Voltage');
s.Rate = Fa;

%
% Inicializacao do vetor que guarda o historico das variaveis
%
vetoruk = zeros(NumberOfTasksToExecute+1,1);
vetoruk(1) = 0; % instante 0 -> k=1
vetoryk = zeros(NumberOfTasksToExecute+1,1);
vetoryk(1) = 0;
% inicializacao da variavel do tempo discreto
k = 1;
% Start the timer
start(tm);
%
% Funcao que e' executada no timer tm periodicamente a cada T    <--------------------------------------
%
function MyTimerFcn(~,~)    
% Leitura da Porta A/D
sample = inputSingleScan(s);     % le o dado do canal de entrada 0, 1    
uk = referencia(k);
% Escolher aqui ou velocidade angular ou posicao angular
yk = sample(1);               % leitura da tensao do tacometro                  
% Escrita na Porta D/A - u(k)
outputSingleScan(s,uk);
% Salva os valores
vetoruk(k) = uk;
vetoryk(k) = yk;
% Update de variaveis    
k = k+1;
end % Fim da funcao MyTymerFcn
% Funcao executada ao final da execucao do timer tm
function StopEverything(~,~)
    outputSingleScan(s,0.0);
    release(s);
    nsamples = length(vetoruk);
    t=0.0:T:(nsamples-1)*T;
    plot(t,vetoryk,'--');
    hold on
    stairs(t,vetoruk);
    grid on
    title('Referencia r(k) / Saida da planta y(k)')
    xlabel('tempo (s)');
    ylabel('tensao (Volts)');
    
    save('lixo')
    
    matdata = [t' vetoruk vetoryk]; % agrupa variaveis de interesse 
        
    % coloque aqui o nome do arquivo onde deseja salvar os dados
    save('OLM4.txt','matdata','-ascii')
    
    mensagem = 'acabou'    
end % Fim de StopEverything
return;
end  % FIM function controlador
