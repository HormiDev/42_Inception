# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: ide-dieg <ide-dieg@student.42madrid.com    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/04/23 17:24:55 by ide-dieg          #+#    #+#              #
#    Updated: 2026/06/27 13:51:54 by ide-dieg         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #


COMPOSE_FILE = srcs/docker-compose.yml
DC = docker compose -f $(COMPOSE_FILE)


all: create_data_directories
	$(DC) up --build -d

down:
	$(DC) down

clean: 
	$(DC) down --rmi local

fclean: clean
	$(DC) down -v --rmi all --remove-orphans

create_data_directories:
	mkdir -p /home/ide-dieg/data/wordpress /home/ide-dieg/data/mariadb

re: fclean all

.PHONY: all down clean fclean re create_data_directories
