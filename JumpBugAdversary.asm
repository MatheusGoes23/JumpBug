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
#								     #
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

#Informações do Adversário:
adversaryHeadX: 	.word 64
adversaryHeadY:	.word 34
actualAdversaryX:	.word 64
actualAdversaryY:	.word 34
initiateY:	.word 0

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
	li $t0,	64   #LARGURA PELA ESQUERDA 
	sw $t0, adversaryHeadX
	
	# spawn do inimigo em Y aleatório
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
	lw $a3, adversaryHeadY		#LIMITE DO TAMNHO POR CIMA
	jal DrawAdversary
	
######################################################
# 	Verificação do input no teclado		     #
######################################################
inputCheck:
	#ADVERSARIO ANDANDO PARA A ESQUERDA
	lw $t6, adversaryHeadX
	addi $t8, $t6, -1
	sw $t8, adversaryHeadX
	addi $t9, $0, -1
	
	beq $t8, $t9, stop
	
	#TEMPO 
	li $a0, 35 		#Tempo velocidade do adversário
	li $v0, 32
	syscall
	
	#Pegando valor digitado no teclado
	li $t0, 0xffff0000 #salvando endereço do bit ready
	lw $t1, ($t0) #acessando bit ready
	andi $t1, $t1, 0x0001 #checando se o bit ready é 1 
	
	#Desenhando o personagem na sua posição inicial
	lw $t5, adversaryColor
	addi $a2, $0, -2   			#POSIÇÃO Y DO ADVERSÁRIO
	lw $a3, adversaryHeadY
	addi $a3, $a3, 1			#TAMANHO POR BAIXO
	jal DrawAdversary
	jal clearAdversary
######################################################
# 	Atualizando posição do adversário	     #
######################################################		

stop:	
	addi $t8, $0, 0
	addi $t8, $0, 64
	sw $t8, adversaryHeadX
	j main
	
clearAdversary:
	#Desenhando o personagem na sua posição inicial
	lw $t8, adversaryHeadX
	addi $t8, $t8, 1
	sw $t8, adversaryHeadX
	
	lw $t5, backgroundColor
	addi $a2, $0, -2   			#POSIÇÃO Y DO ADVERSÁRIO
	lw $a3, adversaryHeadY
	addi $a3, $a3, 1			#TAMANHO POR BAIXO
	
	jal DrawAdversary
	
	lw $t6, adversaryHeadX
	addi $t8, $t6, -1
	sw $t8, adversaryHeadX
	j inputCheck

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
	
###############################################################################
#	Função DrawAdversary						      #
# 	$a2 -> Valor para somar com a coordenada Y e fazer o adversário pular #
# 	$a3 -> Valor do formato do adversário				      #
###############################################################################
DrawAdversary:
	lw $t0, adversaryHeadX #carregando coordenada x
	lw $t1, adversaryHeadY #carregando coordenada y
	addi $t7, $t0, 1
	
FillAdversaryX:
	
	add $a0, $t0, $0 #carregando coordenada x
	sw $a0, actualAdversaryX
	add $a1, $t1, $a2 #carregando coordenada y
	
	beq $t0, $t7, Exit #comparando a largura do adversário  #34  #LARGURA PELA DIREIRA #61
	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp) 
		
	jal FillAdversaryY	#desenhar adversário
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t0, $t0, 1 
	j FillAdversaryX
			
FillAdversaryY:	
	add $a0, $t0, $0 #carregando coordenada x
	add $a1, $t1, $a2 #carregando coordenada y
	sw $a1, actualAdversaryY
		
	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
								
	jal Coordinate #pegando as coordenadas da tela
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	move $a0, $v0 #copiando coordenadas para $a0
	addi $a1, $t5, 0 #carregando a cor do adversário para $a1
	
	beq $t1, $a3, stopFill #comparando se já chegou à altura do adversário

	addi $sp, $sp, -4 #salvando valor de $ra
	sw $ra, 0($sp)
			
	jal DrawPixel	#desenhar adversário
	
	lw $ra, 0($sp) #recuperando valor de $ra
	addi $sp, $sp, 4
	
	addi $t1, $t1, 1
	
	j FillAdversaryY
stopFill:
	lw $t1, adversaryHeadY #carregando coordenada y
	jr $ra
	
Exit:
	jr $ra
