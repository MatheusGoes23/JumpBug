######################################################################
# 			     JUMP BUG!                               #
######################################################################
#              		 Feito por Matheus Goes                      #
######################################################################
#	Este programa requer as ferramentas Keyboard and Display     #
#       MMIO e Bitmap Display conectadas ao MIPS.                    #
#								     #
#       Configurações do Bitmap Display                              #
#	Unit Width: 8						     #
#	Unit Height: 8						     #
#	Display Width: 512					     #
#	Display Height: 512					     #
#	Base Address for Display: 0x10008000 ($gp)		     #
######################################################################
#	Tecla de pulo do jogador: W				     #
######################################################################
	#EXPLICAÇÃO DO JOGO AINDA NÃO COMENTADA!
	#FUNCIONANDO APENAS O ADVERSÁRIO ANDANDO DE FORMA ALEATÓRIA E
	# O JOGADOR PULANDO!

	.data

#Informações no núcleo do jogo:

#Tela:
screenWidth: 	.word 64
screenHeight: 	.word 64

#Cores:
playerColor:	.word	0x001379	# blue
backgroundColor:.word	0xA6BFFF	# sky blue 
floorColor:     .word	0xB85800	# brown	
adversaryColor: .word	0xFF0000	# red

#Mensagens:  #ainda não implementadas
DiedMsg:	.asciiz 	"Você foi atingido. Restam ainda: "
LivesMsg:	.asciiz 	" vidas.\n"
GameOverMsg:	.asciiz 	"GAME OVER!\n"
ScoreMsg:	.asciiz		"Sua pontuação final foi: "
RestartMsg: .asciiz "Deseja reiniciar a partida?"

#Informações do Jogador:
playerHeadX: 	.word 31
playerHeadY:	.word 39
actualPlayerX:	.word 31
actualPlayerY:	.word 39
lives:		.word 3
score: .word 0

#Informações do Adversário:
adversaryHeadX: 	.word 64
adversaryHeadY:		.word 34
actualAdversaryX:	.word 64
actualAdversaryY:	.word 34

#Pular:
jump:		.word 119 #pulo

	.text
reset:
	#Resetando os valores da vida e score
	li $t0, 3
	sw $t0, lives #Resetando a vida
	li $t0, 0
	sw $t0, score #Resetando o score

main:


######################################################
# 	Preenchendo a tela e o chão		     #
######################################################
	lw $a0, screenWidth
	lw $a1, backgroundColor
	mul $a2, $a0, $a0		#Total de pixels da tela
	mul $a2, $a2, 3 		#Alinhando endereços
	add $a2, $a2, $gp 		#Endereço base da tela
	add $a0, $gp, $zero 		#Preenchendo com laço
	
FillBackground:
	beq $a0, $a2, DrawLives
	sw $a1, 0($a0) 			#Armazenando cor
	addiu $a0, $a0, 4 		#Incrementando contador
	j FillBackground
	
DrawLives:
	add $t0, $gp, 260
	lw $t1, lives #Carrega o numero de vidas
LoopLives:
	beq $t2, $t1, Floor 
	lw $a1, adversaryColor
	sw $a1, 0($t0)
	add $t0, $t0, 8
	add $t2, $t2, 1 #Contador
	j LoopLives

Floor:
	addi $t0, $a0, 0
	lw $a1, floorColor
	lw $a0, screenWidth
	mul $a2, $a0, $a0 		#Total de pixels da tela
	mul $a2, $a2, 4 		#Alinhando endereços
	add $a2, $a2, $gp 		#Endereço base da tela
	add $a0, $t0, $zero 		#Laço para preencher

FillFloor:
	beq $a0, $a2, Init
	sw $a1, 0($a0) 			#Armazenando cor
	addiu $a0, $a0, 4 		#Incrementando contador
	j FillFloor

######################################################
# 	Inicializando Variáveis			     #
######################################################
Init:
	li $t0, 31			#Largura do jogador pela esquerda
	sw $t0, playerHeadX
	li $t0, 39			#Tamanho do jogador por cima
	sw $t0, playerHeadY
	
	li $t0, 31
	sw $t0, actualPlayerX
	li $t0, 39
	sw $t0, actualPlayerY
	
	li $t0,	64			#Largura do adversário pela esquerda
	sw $t0, adversaryHeadX
	
	#Gerando altura alatória do adversário
	li $v0, 42
	li $a1, 15
	syscall
	
	addi $a0, $a0, 34
	sw $a0, adversaryHeadY
	addi $t7, $t0, 1
	
	lw $t0, adversaryHeadX
	sw $t0, actualAdversaryX
	lw $t0, adversaryHeadY
	sw $t0, actualAdversaryY

	li $t0, 119
	sw $t0, jump
	
	ClearRegisters:

	li $v0, 0
	li $a0, 0
	li $a1, 0
	li $a2, 0
	li $a3, 0
	li $t0, 0
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $t8, 0
	li $t9, 0
	li $s0, 0
	li $s1, 0
	li $s2, 0
	li $s3, 0
	li $s4, 0
	
######################################################
# 	Desenhando o Adversário			     #
######################################################
	lw $t5, adversaryColor
	lw $a3, adversaryHeadY		#Limite do tamanho do adversário por cima
	jal DrawAdversary

######################################################
# 	Desenhando o Jogador			     #
######################################################
	lw $t5, playerColor
	addi $a2, $0, 0			#Tamanho do jogador por baixo
	addi $a3, $0, 48	 	#Limite do tamanho do tamanho por baixo
	jal DrawPlayer
	
######################################################
# 	Verificação do input no teclado		     #
######################################################
inputCheck:
	#Checando se o adversário atingiu o jogador 
	lw $t8, adversaryHeadX
	lw $t9, playerHeadX
	bne $t8, $t9, Continue		#Checando se o adversário nâo está na mesma coordenada x do jogador
	lw $t8, adversaryHeadY
	lw $t9, playerHeadY
	addi $t0, $t9, 10		#Pé do jogador
	addi $t9, $t9, 2
checkHeadY:
	beq $t9, $t0, Continue
	beq $t8, $t9, playerDied	#Checando se o adversário está na mesma coordenada y do jogador	
	addi $t9, $t9, 1
	j checkHeadY
Continue:
	#Pegando valor digitado no teclado
	li $t0, 0xffff0000 		#Salvando endereço do bit ready
	lw $t1, ($t0) 			#Acessando bit ready
	andi $t1, $t1, 0x0001 		#Checando se o bit ready é 1 
	
	#Adversário andando para a esquerda
	lw $t8, adversaryHeadX
	addi $t8, $t8, -1
	sw $t8, adversaryHeadX
	addi $t9, $0, -1
	beq $t8, $t9, stopAdversary
	
	#Velocidade do jogo
	li $a0, 17 			#Tempo velocidade do adversário e do tempo de pulo do jogador
	li $v0, 32
	syscall
	
	#Pegando valor digitado no teclado
	li $t0, 0xffff0000 		#Salvando endereço do bit ready
	lw $t1, ($t0) 			#Acessando bit ready
	andi $t1, $t1, 0x0001 		#Checando se o bit ready é 1 
	
	#Desenhando o adversário na sua nova posição
	lw $t5, adversaryColor
	addi $a2, $0, -2   		#Coordenadas Y do adversário
	lw $a3, adversaryHeadY
	addi $a3, $a3, 1		#Tamanho do adversário por baixo
	jal DrawAdversary
	
	#Apagando a posição antiga do adversário
	li $t0, 0
	jal clearAdversary
	
######################################################
# 	Atualizando posição do jogador		     #
######################################################		
DrawJump:	
	lw $a1, 0xffff0004 		#Guarda letra digitada em $a1	
	lw $a0, jump 			#Carregando tecla de pulo
	bne $a1, $a0, inputCheck
	sw $0, 0xffff0004
	
	#Jogador pulando
	lw $t5, playerColor
	addi $a2, $0, -12		#Coordenada y do jogador durante o pulo
	addi $a3, $0, 48		#Tamanho do jogador por baixo durante o pulo	
	jal DrawPlayer
	
	#Apagando jogador inicial, antes de pular
	lw $t5, backgroundColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawPlayer
	
	#Desenhando o adversário nas suas novas coordenadas
	lw $t5, adversaryColor
	addi $a2, $0, -2   		#Coordenada y do adversário
	lw $a3, adversaryHeadY
	addi $a3, $a3, 1		#Tamanho do adversário por baixo
	jal DrawAdversary
	
	#Apagando a posição antiga do adversário
	li $t0, 1
	jal clearAdversary
	
return:
	li $t9, 0

while:	
	#Laço para o jogador conseguir ficar um tempo no ar durante o pulo
	beq $t9, 4, stop
	addi $t9, $t9, 1
	j while
	
stopAdversary:	
	#Para quando o adversário andar até limite da tela
	addi $t8, $0, 0
	addi $t8, $0, 64
	sw $t8, adversaryHeadX
	lw $s5, score #Lê a label score
	add $s5, $s5, 1 #Adiciona mais um ao score
	sw $s5, score #Salva o score na memória
	j main
	
clearAdversary:
	#Apagando o adversário a posição antiga do adversário
	lw $t8, adversaryHeadX
	addi $t8, $t8, 1
	sw $t8, adversaryHeadX
	
	lw $t5, backgroundColor
	addi $a2, $0, -2   		#Coordenadas y do adversário
	lw $a3, adversaryHeadY
	addi $a3, $a3, 1		#Tamanho do adversário por baixo
	
	jal DrawAdversary
	
	lw $t6, adversaryHeadX
	addi $t8, $t6, -1		#Nova coordenada x do adversário
	sw $t8, adversaryHeadX
	
	beq $t0, $0, return
	j DrawJump

stop:
	#Apagando jogador que está pulando
	lw $t5, backgroundColor
	addi $a2, $0, -12
	addi $a3, $0, 48
	jal DrawPlayer
	
	#Desenhando o jogador na sua posição inicial
	lw $t5, playerColor
	addi $a2, $0, 0			#Coordenada y do jogador
	addi $a3, $0, 48		#Tamanho do jogador por baixo
	jal DrawPlayer

exitDrawJump:
	j inputCheck #Voltar para entrada do teclado

##################################################################
#			FUNÇÕES					 #	
##################################################################
# 	Função Coordinates					 #
# 	$a0 -> coordenada x					 #
# 	$a1 -> coordenada y					 #
##################################################################
# 	Retorna em $v0 as coordenadas da tela			 #
##################################################################
Coordinate:
	lw $v0, screenWidth 		#Coloca a largura da tela em $v0
	mul $v0, $v0, $a1		#Multiplica pela posição de y da tela
	add $v0, $v0, $a0		#Adiciona com a posição de x da tela
	mul $v0, $v0, 4			#Multiplica por 4
	add $v0, $v0, $gp		#Adiciona ao endereço base da tela
	jr $ra				#Retorna $v0
	
##################################################################
#	Função DrawPixel					 #
# 	$a0 -> Posição para desenhar				 #
# 	$a1 -> Coloração do pixel				 #
##################################################################
DrawPixel:	
	sw $a1, ($a0) 			#Preenche a coordenada com o valor	
	jr $ra				#Retorna
	
###############################################################################
#	Função DrawAdversary						      #
# 	$a2 -> Valor para somar com a coordenada Y e fazer o adversário andar #
# 	$a3 -> Valor do formato do adversário				      #
###############################################################################
DrawAdversary:
	lw $t0, adversaryHeadX 		#Carregando coordenada x do adversário
	lw $t1, adversaryHeadY 		#Carregando coordenada y do adversário
	addi $t7, $t0, 1
	
FillAdversaryX:
	
	add $a0, $t0, $0 		#Carregando coordenada x do adversário
	sw $a0, actualAdversaryX
	add $a1, $t1, $a2 		#Carregando coordenada y do adversário
	
	beq $t0, $t7, Exit 		#Comparando a largura pela direita do adversário
	addi $sp, $sp, -4 		#Salvando valor de $ra
	sw $ra, 0($sp) 
		
	jal FillAdversaryY		#Desenhar adversário
	
	lw $ra, 0($sp) 			#Recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t0, $t0, 1 
	j FillAdversaryX
			
FillAdversaryY:	
	add $a0, $t0, $0 		#Carregando coordenada x do adversário
	add $a1, $t1, $a2 		#Carregando coordenada y do adversário
	sw $a1, actualAdversaryY
		
	addi $sp, $sp, -4 		#Salvando valor de $ra
	sw $ra, 0($sp)
								
	jal Coordinate 			#Pegando as coordenadas da tela
	
	lw $ra, 0($sp) 			#Recuperando valor de $ra
	addi $sp, $sp, 4
	
	move $a0, $v0 			#Copiando coordenadas para $a0
	addi $a1, $t5, 0 		#Carregando a cor do adversário para $a1
	
	beq $t1, $a3, stopFill 		#Comparando se já chegou à altura por baixo do adversário

	addi $sp, $sp, -4 		#Salvando valor de $ra
	sw $ra, 0($sp)
			
	jal DrawPixel			#Desenhar adversário
	
	lw $ra, 0($sp) 			#Recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t1, $t1, 1
	
	j FillAdversaryY
	
############################################################################
#	Função DrawPlayer						   #
# 	$a2 -> Valor para somar com a coordenada Y e fazer o jogador pular #
# 	$a3 -> Valor do formato do jogador				   #
############################################################################
DrawPlayer:
	lw $t0, playerHeadX 		#Carregando coordenada x do jogador
	lw $t1, playerHeadY 		#Carregando coordenada y do jogador
FillPlayerX:
	add $a0, $t0, $0 		#Carregando coordenada x do jogador
	sw $a0, actualPlayerX
	add $a1, $t1, $a2 		#Carregando coordenada y do jogador	
	beq $t0, 32, Exit 		#Comparando a largura do jogador pela direira
	addi $sp, $sp, -4	 	#Salvando valor de $ra
	sw $ra, 0($sp)
		
	jal FillPlayerY			#Desenhar jogador
	
	lw $ra, 0($sp) 			#Recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t0, $t0, 1
	j FillPlayerX
			
FillPlayerY:	
	add $a0, $t0, $0 		#carregando coordenada x do jogador
	add $a1, $t1, $a2 		#carregando coordenada y do jogador
	sw $a1, actualPlayerY
		
	addi $sp, $sp, -4 		#salvando valor de $ra
	sw $ra, 0($sp)
								
	jal Coordinate 			#pegando as coordenadas da tela
	
	lw $ra, 0($sp) 			#recuperando valor de $ra
	addi $sp, $sp, 4
	
	move $a0, $v0 			#copiando coordenadas para $a0
	addi $a1, $t5, 0 		#carregando a cor do jogador para $a1
	
	beq $t1, $a3, stopFill 		#comparando se já chegou à altura por baixo do jogador

	addi $sp, $sp, -4		#salvando valor de $ra
	sw $ra, 0($sp)
			
	jal DrawPixel			#desenhar jogador
	
	lw $ra, 0($sp) 			#recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t1, $t1, 1
	j FillPlayerY
	
stopFill:
	lw $t1, playerHeadY 		#carregando coordenada y do jogador
	lw $t1, adversaryHeadY 		#carregando coordenada y do adverário
	jr $ra
	
Exit:
	jr $ra

playerDied:
	#Checando se ainda há vidas
	lw $t0, lives
	beq $t0, 1, gameOver
	
	#Removendo uma vida
	addi $t0, $t0, -1
	lw $s5, score #lê o score
	add $s5, $s5, -1 #Subtrai 1 do score para não receber nenhum ponto quando o personagem for atingido
	sw $s5, score #Armazena o valor do score
	sw $t0, lives
	
	#Imprimindo a mensagem que foi atingido
	li $v0, 4
	la $a0,	DiedMsg
	syscall
	
	#Imprimindo o número de vidas restantes
	li $v0, 1
	la $a0,	($t0)
	syscall
	
	#Imprimindo a mensagem da quantidades de vidas restantes
	li $v0, 4
	la $a0,	LivesMsg
	syscall
	
	j Continue
	
gameOver:
	#Imprimindo a mensagem de game over
	li $v0, 4
	la $a0,	GameOverMsg
	syscall
	
	#Imprimindo a mensagem de score
	li $v0, 56
	la $a0, ScoreMsg
	lw $a1, score
	syscall
	
	#Perguntar se quer reiniciar a partida
	li $v0, 50
	la $a0, RestartMsg
	syscall
	
	#Testa a resposta do usuario
	beq $a0, 0, reset #Se for 0 o usuário quer reiniciar