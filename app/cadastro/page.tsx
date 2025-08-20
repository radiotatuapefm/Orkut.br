'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase';
import Link from 'next/link';
import { Eye, EyeOff, User, Mail, Phone, MapPin, FileText, Camera } from 'lucide-react';

interface FormData {
  username: string;
  displayName: string;
  email: string;
  password: string;
  confirmPassword: string;
  phone?: string;
  location?: string;
  bio?: string;
}

export default function CadastroPage() {
  const router = useRouter();
  const [formData, setFormData] = useState<FormData>({
    username: '',
    displayName: '',
    email: '',
    password: '',
    confirmPassword: '',
    phone: '',
    location: '',
    bio: ''
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    setError(null);
  };

  const validateForm = (): string | null => {
    // Validações
    if (!formData.username.trim()) return 'Username é obrigatório';
    if (!formData.displayName.trim()) return 'Nome de exibição é obrigatório';
    if (!formData.email.trim()) return 'Email é obrigatório';
    if (!formData.password) return 'Senha é obrigatória';
    
    // Validar formato do username
    if (!/^[a-zA-Z0-9_]{3,20}$/.test(formData.username)) {
      return 'Username deve ter 3-20 caracteres (apenas letras, números e _)';
    }
    
    // Validar email
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      return 'Email inválido';
    }
    
    // Validar senha
    if (formData.password.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    
    // Confirmar senha
    if (formData.password !== formData.confirmPassword) {
      return 'Senhas não coincidem';
    }
    
    return null;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      // Validar formulário
      const validationError = validateForm();
      if (validationError) {
        setError(validationError);
        return;
      }

      console.log('🚀 Iniciando cadastro...');

      // 1. Criar usuário na autenticação do Supabase
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: formData.email,
        password: formData.password,
        options: {
          data: {
            username: formData.username,
            display_name: formData.displayName
          }
        }
      });

      if (authError) {
        console.error('Erro na autenticação:', authError);
        throw authError;
      }

      if (!authData.user) {
        throw new Error('Falha ao criar usuário');
      }

      console.log('✅ Usuário criado na auth:', authData.user.id);

      // 2. Criar perfil na tabela profiles
      const { error: profileError } = await supabase
        .from('profiles')
        .insert({
          id: authData.user.id,
          username: formData.username.toLowerCase(),
          display_name: formData.displayName,
          email: formData.email,
          phone: formData.phone || null,
          location: formData.location || null,
          bio: formData.bio || null,
          photo_url: null, // Será definido depois quando usuário fizer upload
          whatsapp_enabled: !!formData.phone,
          privacy_settings: {
            profile: 'public',
            phone: formData.phone ? 'friends' : 'private'
          },
          fans_count: 0,
          views_count: 0
        });

      if (profileError) {
        console.error('Erro ao criar perfil:', profileError);
        throw profileError;
      }

      console.log('✅ Perfil criado');

      // 3. Criar registro de presença
      const { error: presenceError } = await supabase
        .from('presence')
        .insert({
          profile_id: authData.user.id,
          online: false,
          status: 'offline',
          last_seen: new Date().toISOString()
        });

      if (presenceError) {
        console.warn('Aviso ao criar presença:', presenceError);
        // Não é crítico, continua
      }

      console.log('✅ Presença configurada');

      setSuccess(`Conta criada com sucesso! 
        🆔 ID único gerado: ${authData.user.id}
        👤 Username: ${formData.username}
        📧 Verifique seu email para confirmar a conta.`);

      // Redirecionar após 3 segundos
      setTimeout(() => {
        router.push('/login?message=Conta criada! Faça login para continuar.');
      }, 3000);

    } catch (err: any) {
      console.error('Erro no cadastro:', err);
      setError(err.message || 'Erro ao criar conta');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-100 to-pink-100 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-xl p-8 w-full max-w-md">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent text-3xl font-bold mb-2">
            Orkut Retrô
          </div>
          <p className="text-gray-600">Crie sua conta e conecte-se com amigos!</p>
        </div>

        {/* Formulário */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Username */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nome de Usuário *
            </label>
            <div className="relative">
              <User className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <input
                type="text"
                name="username"
                value={formData.username}
                onChange={handleChange}
                placeholder="Ex: anapaula123"
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                required
              />
            </div>
          </div>

          {/* Nome de Exibição */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nome de Exibição *
            </label>
            <input
              type="text"
              name="displayName"
              value={formData.displayName}
              onChange={handleChange}
              placeholder="Ex: Ana Paula Silva"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              required
            />
          </div>

          {/* Email */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Email *
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleChange}
                placeholder="seu@email.com"
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                required
              />
            </div>
          </div>

          {/* Senha */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Senha *
            </label>
            <div className="relative">
              <input
                type={showPassword ? "text" : "password"}
                name="password"
                value={formData.password}
                onChange={handleChange}
                placeholder="Mínimo 6 caracteres"
                className="w-full pr-10 pl-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
              >
                {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          {/* Confirmar Senha */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Confirmar Senha *
            </label>
            <div className="relative">
              <input
                type={showConfirmPassword ? "text" : "password"}
                name="confirmPassword"
                value={formData.confirmPassword}
                onChange={handleChange}
                placeholder="Digite a senha novamente"
                className="w-full pr-10 pl-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                required
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-3 top-3 text-gray-400 hover:text-gray-600"
              >
                {showConfirmPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          {/* Telefone (opcional) */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Telefone (opcional)
            </label>
            <div className="relative">
              <Phone className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <input
                type="tel"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                placeholder="(11) 99999-9999"
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              />
            </div>
          </div>

          {/* Localização (opcional) */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Localização (opcional)
            </label>
            <div className="relative">
              <MapPin className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <input
                type="text"
                name="location"
                value={formData.location}
                onChange={handleChange}
                placeholder="São Paulo, SP"
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              />
            </div>
          </div>

          {/* Bio (opcional) */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Sobre você (opcional)
            </label>
            <div className="relative">
              <FileText className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
              <textarea
                name="bio"
                value={formData.bio}
                onChange={handleChange}
                placeholder="Conte um pouco sobre você..."
                rows={3}
                className="w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent resize-none"
              />
            </div>
          </div>

          {/* Mensagens de erro/sucesso */}
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-3">
              <p className="text-red-700 text-sm">❌ {error}</p>
            </div>
          )}

          {success && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-3">
              <p className="text-green-700 text-sm whitespace-pre-line">✅ {success}</p>
            </div>
          )}

          {/* Botão de cadastro */}
          <button
            type="submit"
            disabled={loading}
            className="w-full bg-gradient-to-r from-purple-600 to-pink-600 text-white py-3 px-4 rounded-lg font-medium hover:from-purple-700 hover:to-pink-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
          >
            {loading ? (
              <div className="flex items-center justify-center gap-2">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                Criando conta...
              </div>
            ) : (
              'Criar Conta'
            )}
          </button>
        </form>

        {/* Link para login */}
        <div className="mt-6 text-center">
          <p className="text-gray-600">
            Já tem uma conta?{' '}
            <Link 
              href="/login" 
              className="text-purple-600 hover:text-purple-800 font-medium"
            >
              Fazer login
            </Link>
          </p>
        </div>

        {/* Informações sobre o sistema */}
        <div className="mt-6 p-4 bg-blue-50 rounded-lg">
          <h3 className="font-medium text-blue-800 mb-2">🔐 Sistema de Perfis Únicos</h3>
          <ul className="text-sm text-blue-700 space-y-1">
            <li>• ID único gerado automaticamente</li>
            <li>• Perfil individual no banco de dados</li>
            <li>• Suporte para posts, mensagens e amizades</li>
            <li>• Sistema de busca integrado</li>
          </ul>
        </div>
      </div>
    </div>
  );
}
