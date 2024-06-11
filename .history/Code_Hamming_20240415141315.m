close all;
clear all;
clc;

SNRdB = 1:1:12;                           % SNR en dB
SNR = 10.^(SNRdB./10);                     % SNR à l'échelle linéaire
info_word_length = 100000;                 % Nombre de mots d'information
n = 7; 
k = 4;                                     % Paramètres du code de Hamming
num_trials = 4;                            % Nombre d'essais Monte Carlo
ber = zeros(length(SNR), 1);               % BER simulé

info_word = floor(2 * rand(k, info_word_length, num_trials));  % Génération de bits d'information aléatoires
code_bit5 = xor(info_word(1,:,:), xor(info_word(2,:,:), info_word(3,:,:)));   % Premier bit de parité
code_bit6 = xor(info_word(1,:,:), xor(info_word(3,:,:), info_word(4,:,:)));   % Deuxième bit de parité
code_bit7 = xor(info_word(1,:,:), xor(info_word(2,:,:), info_word(4,:,:)));   % Troisième bit de parité
code_word = [info_word; code_bit5; code_bit6; code_bit7];       % Mot d'information codé avec bits de parité
code_word(code_word == 0) = -1;              % Conversion des bits 0 en -1

H = [1 1 1;
     1 1 0; 
     1 0 1; 
     0 1 1; 
     1 0 0; 
     0 1 0; 
     0 0 1];     % Matrice de vérification de parité
C = de2bi((0:2^(k)-1));                       % Tous les bits de longueur k (stockés dans la matrice de mots de code valides 'C')
C(1:16,5) = xor(C(:,1),xor(C(:,2),C(:,3)));   % Premier bit de parité
C(1:16,6) = xor(C(:,1),xor(C(:,3),C(:,4)));   % Deuxième bit de parité
C(1:16,7) = xor(C(:,1),xor(C(:,2),C(:,4)));   % Troisième bit de parité

for t = 1:num_trials
    decoded_bit = zeros(n, info_word_length);             % Sortie de décodage HARD   
    
    for i = 1:length(SNR)
        y = (sqrt(SNR(i)) * code_word(:,:,t)) + randn(n, info_word_length);     % Codes reçus

        % Détection de BIT (Hard)
        decoded_bit(y > 0) = 1;                    % Tous les bits reçus positifs convertis en 1
        decoded_bit(y < 0) = 0;                    % Tous les bits reçus négatifs convertis en 0

        ber(i) = ber(i) + length(find(decoded_bit(1:4,:) ~= info_word(:,:,t)));     % BER dans la détection de BIT
    end
end

ber = ber / (k * info_word_length * num_trials);
semilogy(SNRdB, ber, 'r-o', 'linewidth', 2.0)    % BER simulé dans le décodage HARD
hold on;
p = qfunc(sqrt(SNR));
BER_H = zeros(1, length(SNR));
for j = 2:n
    BER_H = BER_H + nchoosek(n, j) * (p.^j) .* ((1 - p).^(n - j));
end

semilogy(SNRdB, BER_H, 'k->', 'linewidth', 2.0);         % BER théorique dans le décodage HARD
hold on;
title('Détection de BIT pour le code de Hamming (7,4)');
xlabel('SNR (dB)');
ylabel('BER');
legend('BER simulé ', 'BER théorique ');
axis tight
grid on
