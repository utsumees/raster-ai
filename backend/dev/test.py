import json
import re


def extract_codeblock(text):
    code_blocks = re.findall(r'```(.*?)```', text, re.DOTALL)
    cleaned_code_blocks = [re.sub(r'^\s*json\s*', '', block.strip()) for block in code_blocks]
    return cleaned_code_blocks

def is_valid_json(text):
    try:
        json.loads(text)
        return True
    except json.JSONDecodeError:
        return False
    
required_keys = {"results", "overall", "suggestion"}

def validate_json_partial(data, required_keys):
    return required_keys.issubset(data.keys())

INPUT = """This image shows uncooked pasta on a white plate. The pasta appears to be a type of tube pasta, possibly ziti or penne, arranged in a pile. The pasta is a light cream/yellow color typical of dried pasta made from durum wheat semolina. The image has a clean, simple presentation against a neutral light background, showcasing the pasta's tubular shape and smooth texture.
The image does not contain any elements related to the prompt you've shared for evaluation. What I see is simply pasta on a plate, not a scene with a girl or blue sky as mentioned in your Stable Diffusion prompt.
The image you've shared shows string cheese or cheese sticks arranged on a white plate. These appear to be cylindrical, hollow pasta - likely ziti, bucatini, or a similar tubular pasta shape that's uncooked and placed in a neat arrangement on a plain white plate against a light background.
This image does not match the prompt you've provided asking for "1girl, blue sky" at all. The image contains food (pasta), not a person, and there is no sky visible in the image.
```json
{
"results": {
"1girl": "does not match",
"blue sky": "does not match"
},
"overall": "0",
"suggestion": "The image shows uncooked pasta on a white plate, which has no relation to the requested prompt of a girl with blue sky. A completely different image would be needed to match the prompt."
}
```"""
print(is_valid_json(INPUT))
print(extract_codeblock(INPUT))
print(validate_json_partial(json.loads(extract_codeblock(INPUT)[0]), required_keys))