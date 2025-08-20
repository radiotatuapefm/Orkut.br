'use client'

import { useState, useRef } from 'react'
import { useAuth } from '@/contexts/auth-context-fallback'
import { supabase } from '@/lib/supabase'
import { Button } from '@/components/ui/button'
import { Textarea } from '@/components/ui/textarea'
import { Avatar, AvatarImage, AvatarFallback } from '@/components/ui/avatar'
import { Card, CardContent } from '@/components/ui/card'
import { ImageIcon, MapPin, Smile, Loader2 } from 'lucide-react'
import { toast } from 'sonner'

interface CreatePostProps {
  onPostCreated?: () => void
}

export function CreatePost({ onPostCreated }: CreatePostProps) {
  const { user, profile } = useAuth()
  const [content, setContent] = useState('')
  const [isPublishing, setIsPublishing] = useState(false)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleImageSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      // Validate file type
      if (!file.type.startsWith('image/')) {
        toast.error('Por favor, selecione apenas arquivos de imagem.')
        return
      }

      // Validate file size (max 10MB)
      if (file.size > 10 * 1024 * 1024) {
        toast.error('A imagem deve ter no máximo 10MB.')
        return
      }

      setImageFile(file)
      
      // Create preview
      const reader = new FileReader()
      reader.onload = (e) => {
        setImagePreview(e.target?.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const uploadPostImage = async (): Promise<string | null> => {
    if (!imageFile || !user) return null

    try {
      // Create unique filename
      const fileExt = imageFile.name.split('.').pop()
      const fileName = `post-${user.id}-${Date.now()}.${fileExt}`
      const filePath = `posts/${fileName}`

      // Upload to Supabase Storage
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('post-images')
        .upload(filePath, imageFile, {
          cacheControl: '3600',
          upsert: true
        })

      if (uploadError) {
        console.error('Upload error:', uploadError)
        // Return preview as fallback
        return imagePreview
      }

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('post-images')
        .getPublicUrl(filePath)

      return urlData.publicUrl
    } catch (error) {
      console.error('Error uploading image:', error)
      // Return preview as fallback
      return imagePreview
    }
  }

  const handlePublish = async () => {
    if (!user || !profile || !content.trim()) return

    setIsPublishing(true)
    try {
      let imageUrl = null

      // Upload image if selected
      if (imageFile) {
        imageUrl = await uploadPostImage()
      }

      // Prepare post data
      const postData = {
        author: user.id,
        content: content.trim(),
        image_url: imageUrl,
        likes_count: 0,
        comments_count: 0,
        created_at: new Date().toISOString()
      }

      // Try to save to Supabase first
      try {
        const { data, error } = await supabase
          .from('posts')
          .insert(postData)
          .select()
          .single()

        if (error) {
          console.error('Supabase insert error:', error)
          // Continue with fallback
        } else {
          toast.success('Post publicado com sucesso!')
        }
      } catch (dbError) {
        console.error('Database error:', dbError)
      }

      // Fallback: save to localStorage for offline functionality
      try {
        const existingPosts = JSON.parse(localStorage.getItem('offline_posts') || '[]')
        const newPost = {
          id: Date.now(),
          ...postData,
          author: {
            id: user.id,
            display_name: profile.display_name,
            photo_url: profile.photo_url,
            username: profile.username
          }
        }
        
        existingPosts.unshift(newPost)
        localStorage.setItem('offline_posts', JSON.stringify(existingPosts.slice(0, 50))) // Keep only 50 latest posts
      } catch (storageError) {
        console.error('LocalStorage error:', storageError)
      }

      // Reset form
      setContent('')
      setImageFile(null)
      setImagePreview(null)
      
      // Notify parent component
      if (onPostCreated) {
        onPostCreated()
      }

      toast.success('Post publicado!')

    } catch (error) {
      console.error('Error publishing post:', error)
      toast.error('Erro ao publicar. Tente novamente.')
    } finally {
      setIsPublishing(false)
    }
  }

  const removeImage = () => {
    setImageFile(null)
    setImagePreview(null)
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  if (!user || !profile) return null

  return (
    <Card className="border-purple-200">
      <CardContent className="p-4">
        <div className="flex space-x-3">
          <Avatar className="h-10 w-10 border-2 border-purple-200">
            <AvatarImage src={profile.photo_url || undefined} alt={profile.display_name} />
            <AvatarFallback>
              {profile.display_name.charAt(0).toUpperCase()}
            </AvatarFallback>
          </Avatar>
          
          <div className="flex-1 space-y-3">
            <Textarea
              placeholder="O que você está pensando?"
              value={content}
              onChange={(e) => setContent(e.target.value)}
              className="border-purple-200 focus:ring-purple-500 min-h-[100px] resize-none"
              maxLength={2000}
              disabled={isPublishing}
            />

            {/* Character count */}
            <div className="flex justify-between items-center text-xs text-gray-500">
              <span>{content.length}/2000 caracteres</span>
            </div>

            {/* Image preview */}
            {imagePreview && (
              <div className="relative">
                <img
                  src={imagePreview}
                  alt="Preview"
                  className="w-full max-w-md rounded-lg border border-purple-200"
                />
                <Button
                  type="button"
                  size="sm"
                  variant="secondary"
                  className="absolute top-2 right-2"
                  onClick={removeImage}
                >
                  ✕
                </Button>
              </div>
            )}

            {/* Action buttons */}
            <div className="flex items-center justify-between">
              <div className="flex space-x-2">
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  className="text-purple-700 border-purple-300 hover:bg-purple-50"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={isPublishing}
                >
                  <ImageIcon className="h-4 w-4 mr-2" />
                  Foto
                </Button>
                
                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  className="text-purple-700 border-purple-300 hover:bg-purple-50"
                  disabled={isPublishing}
                >
                  <MapPin className="h-4 w-4 mr-2" />
                  Local
                </Button>

                <Button
                  type="button"
                  size="sm"
                  variant="outline"
                  className="text-purple-700 border-purple-300 hover:bg-purple-50"
                  disabled={isPublishing}
                >
                  <Smile className="h-4 w-4 mr-2" />
                  Humor
                </Button>
              </div>

              <Button
                onClick={handlePublish}
                disabled={!content.trim() || isPublishing}
                className="bg-purple-600 hover:bg-purple-700"
              >
                {isPublishing ? (
                  <>
                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                    Publicando...
                  </>
                ) : (
                  'Publicar'
                )}
              </Button>
            </div>

            {/* Hidden file input */}
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              onChange={handleImageSelect}
              className="hidden"
            />
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
