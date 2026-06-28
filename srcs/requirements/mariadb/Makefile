
NAME = mariadb

$(NAME):
	docker build -t $(NAME) .
	docker run -p 8088:443 -it --name $(NAME) $(NAME)

all: $(NAME)

clean: 
	docker rmi $(NAME) 2>/dev/null || true

fclean: clean
	docker rm $(NAME) 2>/dev/null || true
	

re: fclean all