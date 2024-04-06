for dir in $(find . -type f -name "*.tfstate" | cut -d / -f 2); do
	(
		cd $dir
		terraform destroy -auto-approve
	)
done
