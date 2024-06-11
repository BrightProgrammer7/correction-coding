close all; clear all; clc;

% Définition des paramètres
SNRdB = 1:1:10;                             % SNR en dB
SNR = 10.^(SNRdB./10);                       % SNR en échelle linéaire
info_word_length = 100;                      % Nombre de mots d'information
n = 7; k = 4;                                % Paramètres du code de Hamming
ber = zeros(length(SNR), 1);                 % BER simulé

% Génération des mots d'information et encodage
info_word = floor(2 * rand(k, info_word_length));    % Génération des bits d'information
code_word = encode7_4(info_word);                    % Mot codé avec les bits de parité
code_word(code_word == 0) = -1;                      % Conversion des bits 0 en -1
decoded_bit = zeros(n, info_word_length);            % Sortie du décodage dur

% Simulation de Monte Carlo
num_iterations = 1000;  % Nombre d'itérations

for iter = 1:num_iterations
    for i = 1:length(SNR)
        % Ajout de bruit gaussien
        y = awgn(code_word, SNRdB(i), 'measured');    % Codes reçus

        % Détection BIT (dure)
        decoded_bit(y > 0) = 1;                  % Conversion des bits positifs reçus en +1
        decoded_bit(y < 0) = 0;                  % Conversion des bits négatifs reçus en 0

        % Décodage des codes reçus en mots de code valides
        
            % Décodage dur
            decoded_bit = decodeHard(decoded_bit);
       

        % Calcul du BER dans la détection BIT
        ber(i, 1) = ber(i, 1) + length(find(decoded_bit([3, 5, 6, 7], :) ~= info_word));
    end
end

% Calcul du BER moyen sur toutes les itérations
ber = ber / (k * info_word_length * num_iterations);

% Tracé du BER simulé en décodage dur
semilogy(SNRdB, ber(:, 1), 'r-<', 'linewidth', 2.0);
hold on

% Calcul du BER théorique en décodage dur
p = qfunc(sqrt(SNR));
BER_HARD = zeros(1, length(SNR));
for j = 2:n
    BER_HARD = BER_HARD+ nchoosek(n, j) .* (p.^j) .* ((1 - p).^(n - j));
end
 BER_HARD=3/n*BER_HARD;
semilogy(SNRdB, BER_HARD, 'k-', 'linewidth', 2.0);

% Configuration du titre et des axes
title('BER pour le code de Hamming (7,4)');
xlabel('SNR (dB)');
ylabel('BER');
legend('BER simulé (Décodage dur)', 'BER théorique (Décodage dur)');
axis tight
grid
