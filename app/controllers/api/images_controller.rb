class Api::ImagesController < ApplicationController
    def juicebox
        headers = {
            params: {
                returnFaceLandmarks: true
            },
            'Ocp-Apim-Subscription-Key': ENV['azure_face_api_key'],
            'Content-Type': 'application/json'
        }
        api_url = "https://westcentralus.api.cognitive.microsoft.com/face/v1.0/detect"

        body = {
            url: image_url
        }

        response = begin
            RestClient.post(api_url, JSON.generate(body), headers)
        rescue RestClient::BadRequest => e
            return "Found an image, but couldn't find a face"
        end

        data = JSON.parse(response.body)[0]

        return "Found an image, but couldn't find a face" unless data
        face_landmarks = data['faceLandmarks']
        pupil_left = face_landmarks['pupilLeft']
        pupil_right = face_landmarks['pupilRight']
        mouth_left = face_landmarks['mouthLeft']
        mouth_right = face_landmarks['mouthRight']
        mouth_middle = {
            x: mouth_left['x'] + (mouth_right['x'] - mouth_left['x']) / 2,
            y: [mouth_right['y'], mouth_left['y']].min + (mouth_right['y'] - mouth_left['y']) / 2
        }

        base_image = MiniMagick::Image.open(image_url)
        juicebox = MiniMagick::Image.open(File.join(Dir.pwd, "assets/juicebox.png"))
        
        width = (pupil_right['x'] - pupil_left['x']) * 1.5
        scale = juicebox.width / width

        juicebox.resize "#{width}x#{juicebox.height * scale}"
        composite = base_image.composite(juicebox) do |c|
            c.compose "Over"
            c.geometry "+#{mouth_middle[:x]}+#{mouth_middle[:y]}"
        end
        composite.tempfile.open
        event.send_file composite.tempfile
        composite.tempfile.close
    end
end
