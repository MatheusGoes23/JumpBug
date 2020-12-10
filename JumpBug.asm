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

	.data

#Informações no núcleo do jogo:

#Tela:
screenWidth: 	.word 64
screenHeight: 	.word 64

#Cores:
playerColor:	.word	0x001379	#blue
backgroundColor:.word	0xA6BFFF	# sky blue 
floorColor:     .word	0xB85800	# brown	
adversaryColor: .word	0xFF0000	# red

#Mensagens:  #ainda não implementadas
DiedMsg:	.asciiz 	"Você foi atingido. Restam ainda: "
LivesMsg:	.asciiz 	" vidas.\n"
GameOverMsg:	.asciiz 	"GAME OVER!\n"
ScoreMsg:	.asciiz		"Sua pontuação final foi: "

#Informações do Jogador:
playerHeadX: 	.word 30
playerHeadY:	.word 39
actualPlayerX:	.word 30
actualPlayerY:	.word 39
initiateY:	.word 0

#Pular:
jump:		.word 119 #pulo

	.text
main:
######################################################
# 	Preenchendo a tela e o chão		     #
######################################################
	lw $a0, screenWidth
	lw $a1, backgroundColor
	mul $a2, $a0, $a0 #total de pixels da tela
	mul $a2, $a2, 3 #alinhando endereços
	add $a2, $a2, $gp #endereço base da tela
	add $a0, $gp, $zero #preenchendo com laço
	
FillBackground:
	beq $a0, $a2, Floor
	sw $a1, 0($a0) #armazenando cor
	addiu $a0, $a0, 4 #incrementando contador
	j FillBackground

Floor:
	addi $t0, $a0, 0
	lw $a1, floorColor
	lw $a0, screenWidth
	mul $a2, $a0, $a0 #total de pixels da tela
	mul $a2, $a2, 4 #alinhando endereços
	add $a2, $a2, $gp #endereço base da tela
	add $a0, $t0, $zero #laço para preencher

FillFloor:
	beq $a0, $a2, Init
	sw $a1, 0($a0) #armazenando cor
	addiu $a0, $a0, 4 #incrementando contador
	j FillFloor

######################################################
# 	Inicializando Variáveis			     #
######################################################
Init:
	li $t0, 30
	sw $t0, playerHeadX
	li $t0, 39
	sw $t0, playerHeadY
	
	li $t0, 30
	sw $t0, actualPlayerX
	li $t0, 39
	sw $t0, actualPlayerY

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
# 	Desenhando o Jogador			     #
######################################################
	lw $t5, playerColor
	addi $a2, $0, 0 
	addi $a3, $0, 48
	jal DrawPlayer
	
######################################################
# 	Verificação do input no teclado		     #
######################################################
inputCheck:
	lw $t1, actualPlayerX	
	add $t4, $t1, $0
	addi $t2, $t2, -10
	
	#Pegando valor digitado no teclado
	li $t0, 0xffff0000 #salvando endereço do bit ready
	lw $t1, ($t0) #acessando bit ready
	andi $t1, $t1, 0x0001 #checando se o bit ready é 1 
	
	#Desenhando o personagem na sua posição inicial
	lw $t5, playerColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawPlayer
	
######################################################
# 	Atualizando posição do jogador		     #
######################################################		
DrawJump:	
	lw $a1, 0xffff0004 #Guarda letra digitada em $a1	
	lw $a0, jump # Carregando tecla de pulo
	bne $a1, $a0, inputCheck
	sw $0, 0xffff0004
	
	#Atualizar jogador pulando se a tecla digitada for igual a tecla de pulo
	#Desenhando jogador pulando
	lw $t5, playerColor
	addi $a2, $0, -12
	addi $a3, $0, 48
	jal DrawPlayer
	
	#Apagando jogador inicial, antes de pular
	lw $t5, backgroundColor
	addi $a2, $0, 0
	addi $a3, $0, 48
	jal DrawPlayer
	
	li $t9, 0
while:	beq $t9, 1, stop

	li $a0, 680 #Tempo de pulo do jogador
	li $v0, 32
	syscall

	addi $t9, $t9, 1
	j while

stop:	lw $a2, initiateY
	addi $a2, $a2, 0
	addi $t7, $t7, 0
	addi $t6, $t6, 0
	lw $t5, backgroundColor
	lw $a2, initiateY

	#Apagando jogador que esta pulando
	lw $t5, backgroundColor
	addi $a2, $0, -12
	addi $a3, $0, 48
	jal DrawPlayer
	
	lw $t5, playerColor
	addi $a2, $0, 0
	addi $a3, $0, 48
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
	lw $v0, screenWidth 	#Coloca a largura da tela em $v0
	mul $v0, $v0, $a1	#multiplica pela posição de y
	add $v0, $v0, $a0	#adiciona com a posição de x
	mul $v0, $v0, 4		#multiplica por 4
	add $v0, $v0, $gp	#adiciona ao endereço base da tela
	jr $ra			# retorna $v0
	
##################################################################
#	Função DrawPixel					 #
# 	$a0 -> Posição para desenhar				 #
# 	$a1 -> Coloração do pixel				 #
##################################################################
DrawPixel:	
	sw $a1, ($a0) 	#preenche a coordenada com o valor	
	jr $ra		#retorna
	
############################################################################
#	Função DrawPlayer						   #
# 	$a2 -> Valor para somar com a coordenada Y e fazer o jogador pular #
# 	$a3 -> Valor do formato do jogador				   #
############################################################################
DrawPlayer:
	lw $t0, playerHeadX #carregando coordenada x
	lw $t1, playerHeadY #carregando coordenada y
FillPlayerX:
	add $a0, $t0, $0 #carregando coordenada x
	sw $a0, actualPlayerX
	add $a1, $t1, $a2 #carregando coordenada y	
	beq $t0, 34, Exit #comparando a largura do jogador  
	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
		
	jal FillPlayerY	#desenhar jogador
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t0, $t0, 1
	j FillPlayerX
			
FillPlayerY:	
	add $a0, $t0, $0 #carregando coordenada x
	add $a1, $t1, $a2 #carregando coordenada y
	sw $a1, actualPlayerY
		
	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
								
	jal Coordinate #pegando as coordenadas da tela
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	move $a0, $v0 #copiando coordenadas para $a0
	addi $a1, $t5, 0 #carregando a cor do jogador para $a1
	
	beq $t1, $a3, stopFill #comparando se já chegou à altura do jogador

	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
			
	jal DrawPixel	#desenhar jogador
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t1, $t1, 1
	j FillPlayerY
stopFill:
	lw $t1, playerHeadY #carregando coordenada y
	jr $ra
	
Exit:
	jr $ra
