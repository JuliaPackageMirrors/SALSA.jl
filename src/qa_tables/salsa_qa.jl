function salsa_qa{N <: Number}(X::Matrix{N})
	read_char = () -> lowercase(readline(STDIN)[1])
	read_int  = () -> try parse(Int,readline(STDIN)[1]) catch '\n' end
	salsa_qa(X,read_char,read_int)
end

function salsa_qa{N <: Number}(X::Matrix{N}, read_char::Function, read_int::Function)
	proto = SALSAModel(); indices = Array{Int}(0)
	get_key   = (ans) -> typeof(ans) == Char ? ans : 'y'

	n1q = "\nDo you have any target variable of interest in X (or ENTER for default 'yes')? [y/n]: "
	n2q = "\nPlease provide the column number of your target variable (or ENTER for default last column): "
	n3q = "\nIs your problem of the classification type (or ENTER for default 'yes')? [y/n]: "
	n4q = "\nClustering mode is selected. Please provide the number of clusters: "
	n5q = "\nPlease select a loss function from options (or ENTER for default)\n $(print_opts(loss_opts,2)): "
	n6q = "\nDo you want to perform Nyström (nonlinear) approximation (or ENTER for default)? [y/n]\n $(print_opts(mode_opts,'n')): "
	n7q = "\nPlease select an algorithm from options (or ENTER for default)\n $(print_opts(algo_opts,2)): "
	n8q = "\nPlease select a cross-validation (CV) criterion from options (or ENTER for default)\n $(print_opts(criterion_opts,2)): "
	n9q = "\nPlease select a global optimization method from options (or ENTER for default)\n $(print_opts(optim_opts,1)): "
	n10q = "\nPlease select a type of Kernel for Nyström approximation from options (or ENTER for default)\n $(print_opts(kernel_opts,3)): "

	n1 = LinearQANode(n1q, read_char)
	n2 = LinearQANode(n2q, read_int)
	n3 = LinearQANode(n3q, read_char)
	n4 = LinearQANode(n4q, read_int)
	n5 = LinearQANode(n5q, read_int)
	n6 = LinearQANode(n6q, read_char)
	n7 = LinearQANode(n7q, read_int)
	n8 = LinearQANode(n8q, read_int)
	n9 = LinearQANode(n9q, read_int)
	n10= LinearQANode(n10q, read_int)

	n1.options = @compat Dict('y' => QAOption((ans) -> Void, @compat Nullable(n2)),
					  		  'n' => QAOption((ans) -> Void, @compat Nullable(n4)),
					  		  '\n' => QAOption((ans)-> Void, @compat Nullable(n2)))
	n2.options = @compat Dict('y' => QAOption((ans) -> append!(indices,[setdiff(1:size(X,2),ans);ans]), @compat Nullable(n3)),
							  '\n' => QAOption((ans)-> append!(indices,1:1:size(X,2)), @compat Nullable(n3)))
	n3.options = @compat Dict('y' => QAOption((ans) -> Void, @compat Nullable(n5)),
					  		  'n' => QAOption((ans) -> begin proto = SALSAModel(LEAST_SQUARES,proto);
					  						   				 proto.process_labels = false end, Nullable(n6)),
					  		  '\n' => QAOption((ans)-> Void, @compat Nullable(n5)))
	n4.options = @compat @compat Dict('y' => QAOption((ans) -> 
										proto[1] = SALSAModel(LINEAR,RK_MEANS(PEGASOS,ans,20,Euclidean()),LEAST_SQUARES,
										validation_criterion=SILHOUETTE(),global_opt=DS([1]),process_labels=false), @compat Nullable()))
	n5.options = @compat Dict('y' => QAOption((ans) -> proto = SALSAModel(loss_opts[ans],proto), @compat Nullable(n6)),
							  '\n' => QAOption((ans)-> proto = SALSAModel(loss_opts[2],proto), @compat Nullable(n6)))
	n6.options = @compat Dict('n' => QAOption((ans) -> proto = SALSAModel(mode_opts[ans],proto), @compat Nullable(n7)),
					  		  'y' => QAOption((ans) -> proto = SALSAModel(mode_opts[ans],proto), @compat Nullable(n10)),
					  		  '\n' => QAOption((ans)-> proto = SALSAModel(mode_opts['n'],proto), @compat Nullable(n7)))
	n7.options = @compat Dict('y' => QAOption((ans) -> proto = SALSAModel(algo_opts[ans],proto), @compat Nullable(n8)),
							  '\n' => QAOption((ans)-> proto = SALSAModel(algo_opts[2],proto), @compat Nullable(n8)))
	n8.options = @compat Dict('y' => QAOption((ans) -> proto.validation_criterion = criterion_opts[ans], @compat Nullable(n9)),
							  '\n' => QAOption((ans)-> proto.validation_criterion = criterion_opts[2], @compat Nullable(n9)))
	n9.options = @compat Dict('y' => QAOption((ans) -> proto.global_opt = optim_opts[ans], @compat Nullable()),
							  '\n' => QAOption((ans)-> proto.global_opt = optim_opts[1], @compat Nullable()))
	n10.options= @compat Dict('y' => QAOption((ans) -> proto = SALSAModel(kernel_opts[ans],proto), @compat Nullable(n7)),
							  '\n' => QAOption((ans)-> proto = SALSAModel(kernel_opts[3],proto), @compat Nullable(n7)))

	current = @compat Nullable(n1)

	while ~isnull(current)
		node = get(current)
		print_with_color(:blue,node.question)
		ans = node.procfunc()
		node.answer = "$ans"
		key = get_key(ans)
		option = node.options[key]
		option.updatefunc(ans)
		current = option.next
	end

	if length(indices) == 0
		Y = ones(size(X,1),1)
	else
		Y = X[:,indices[end]]
		X = X[:,indices[2:end-1]]
	end

	@printf "\nComputing the model...\n"
	salsa(X,Y,proto,X)
end

function print_opts(opts,default)
	s = ""
	for (key, val) in sort(collect(opts),by=x->x[1])
		s = (key == default) ? string(s,"\t$key : $val (default)\n") : string(s,"\t$key : $val\n")
	end
	s
end