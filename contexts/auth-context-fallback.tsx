'use client'

import { createContext, useContext, useEffect, useState, ReactNode } from 'react'

// Simplified profile type for fallback mode
type Profile = {
  id: string
  username: string
  display_name: string
  photo_url: string | null
  relationship: string | null
  location: string | null
  birthday: string | null
  bio: string | null
  fans_count: number
  created_at: string
}

interface User {
  id: string
  email?: string
}

interface AuthContextType {
  user: User | null
  profile: Profile | null
  loading: boolean
  signIn: (email: string, password: string) => Promise<void>
  signUp: (email: string, password: string, userData: { username: string, displayName: string }) => Promise<void>
  signOut: () => Promise<void>
  updateProfile: (updates: Partial<Profile>) => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

interface AuthProviderProps {
  children: ReactNode
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [user, setUser] = useState<User | null>(null)
  const [profile, setProfile] = useState<Profile | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    console.log('Starting fallback auth context')
    
    // Check if there's a stored session
    const storedUser = localStorage.getItem('orkut_user')
    const storedProfile = localStorage.getItem('orkut_profile')
    
    if (storedUser && storedProfile) {
      try {
        setUser(JSON.parse(storedUser))
        setProfile(JSON.parse(storedProfile))
      } catch (error) {
        console.error('Error parsing stored data:', error)
        localStorage.removeItem('orkut_user')
        localStorage.removeItem('orkut_profile')
      }
    }
    
    // Always stop loading after 2 seconds max
    setTimeout(() => {
      setLoading(false)
    }, 2000)
  }, [])

  const signIn = async (email: string, password: string) => {
    // Simulate login for fallback mode
    const mockUser: User = {
      id: `user_${Date.now()}`,
      email: email
    }
    
    const mockProfile: Profile = {
      id: mockUser.id,
      username: email.split('@')[0],
      display_name: email.split('@')[0],
      created_at: new Date().toISOString(),
      photo_url: null,
      bio: null,
      location: null,
      birthday: null,
      relationship: null,
      fans_count: 0
    }
    
    // Store in localStorage
    localStorage.setItem('orkut_user', JSON.stringify(mockUser))
    localStorage.setItem('orkut_profile', JSON.stringify(mockProfile))
    
    setUser(mockUser)
    setProfile(mockProfile)
  }

  const signUp = async (
    email: string, 
    password: string, 
    userData: { username: string, displayName: string }
  ) => {
    // Simulate signup for fallback mode
    const mockUser: User = {
      id: `user_${Date.now()}`,
      email: email
    }
    
    const mockProfile: Profile = {
      id: mockUser.id,
      username: userData.username,
      display_name: userData.displayName,
      created_at: new Date().toISOString(),
      photo_url: null,
      bio: null,
      location: null,
      birthday: null,
      relationship: null,
      fans_count: 0
    }
    
    // Store in localStorage
    localStorage.setItem('orkut_user', JSON.stringify(mockUser))
    localStorage.setItem('orkut_profile', JSON.stringify(mockProfile))
    
    setUser(mockUser)
    setProfile(mockProfile)
  }

  const signOut = async () => {
    // Clear stored data
    localStorage.removeItem('orkut_user')
    localStorage.removeItem('orkut_profile')
    
    setUser(null)
    setProfile(null)
  }

  const updateProfile = async (updates: Partial<Profile>) => {
    if (!profile) return
    
    const updatedProfile = { ...profile, ...updates }
    localStorage.setItem('orkut_profile', JSON.stringify(updatedProfile))
    setProfile(updatedProfile)
  }

  const value: AuthContextType = {
    user,
    profile,
    loading,
    signIn,
    signUp,
    signOut,
    updateProfile
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}
