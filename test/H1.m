close all; clear all; clc;

SNRdB = 1;                                   % SNR en dB
info_word_length = 100;                      % Nombre de mots d'information
n = 7; k = 4;                                % Paramètres du code de Hamming (7,4)
num_iterations = 1000;                       % Nombre d'itérations pour la simulation de Monte Carlo
ber_sum = 0;                                 % Somme du BER sur toutes les itérations

for iter = 1:num_iterations
    info_word = floor(2 * rand(k, info_word_length));    % Génération de 0 et 1 pour les bits d'information
    code_word = encode7_4(info_word);                    % Mot codé avec les bits de parité
    code_word(code_word == 0) = -1;                      % Conversion des bits 0 en -1
    decoded_bit = zeros(n, info_word_length);            % Sortie du décodage dur

    y = awgn(code_word, SNRdB, 'measured');             % Codes reçus
    
    % Pour la détection BIT (dure)
    decoded_bit(y > 0) = 1;                             % Tous les bits reçus positifs sont convertis en +1
    decoded_bit(y < 0) = 0;                             % Tous les bits reçus négatifs sont convertis en 0
    
    % Décodage des codes reçus en mots de code valides
   
        % Décodage dur
        decoded_bit = decodeHard(decoded_bit);
   
    
    % Calcul du BER dans la détection BIT
    ber = length(find(decoded_bit([3, 5, 6, 7], :) ~= info_word)) / (k * info_word_length);
    ber_sum = ber_sum + ber;
end

% BER moyen sur toutes les itérations
avg_ber = ber_sum / num_iterations;
disp(['BER moyen sur ', num2str(num_iterations), ' itérations : ', num2str(avg_ber)]);
