import json

def lambda_handler(event, context):
    
    print(json.dumps(event))
    # print(json.dumps(context))

    return "hello world lambda"