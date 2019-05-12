def check_sdgs_3_13(profile): #checks in SDGs 3 and 13 are selected
    has_sdg3 = "no"
    has_sdg13 = "no"
    questions = profile.find_all("ul", class_='questionnaire')
    if len(questions) == 2:
        sdgs = questions[0].find_all("li")
        if len(sdgs) != 18:  # the correct SDG questionnaire has 17 questions + header
            temp_sdgs = questions[1].find_all("li")
            if len(temp_sdgs) == 18:
                sdgs = temp_sdgs
            else:
                sdgs = []
        if 'selected_question' in sdgs[3].get('class'):
            has_sdg3 = "yes"
        if 'selected_question' in sdgs[13].get('class'):
            has_sdg13 = "yes"
    return (has_sdg3, has_sdg13)

    
